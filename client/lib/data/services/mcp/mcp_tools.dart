/// Tool names exposed over MCP.
///
/// Every name is prefixed `noo_`: an agent commonly has several MCP servers
/// mounted at once and they share one tool namespace, so `search_tasks` would
/// be a collision waiting to happen.
class McpToolNames {
  McpToolNames._();

  static const String searchTasks = 'noo_search_tasks';
  static const String getTree = 'noo_get_tree';
  static const String getTask = 'noo_get_task';
  static const String createTask = 'noo_create_task';
  static const String updateTask = 'noo_update_task';
  static const String moveTask = 'noo_move_task';
  static const String deleteTask = 'noo_delete_task';

  static const Set<String> read = {searchTasks, getTree, getTask};
  static const Set<String> write = {
    createTask,
    updateTask,
    moveTask,
    deleteTask,
  };

  static const Set<String> all = {...read, ...write};
}

/// Caps that keep a single tool result inside what an agent can actually read.
///
/// Claude Code warns past 10k tokens of tool output and truncates at 25k, so a
/// whole-outline dump is worse than useless — it arrives shortened at an
/// arbitrary point. Every bulk reader here reports that it truncated instead,
/// which is the signal to recurse with a narrower root.
class McpLimits {
  McpLimits._();

  static const int defaultSearchLimit = 20;
  static const int maxSearchLimit = 100;
  static const int defaultTreeDepth = 3;
  static const int maxTreeDepth = 10;
  static const int maxTreeNodes = 2000;

  /// Longest ancestor walk before a corrupt parent cycle is assumed.
  static const int maxPathDepth = 64;
}

/// The `tools/list` payload.
///
/// Write tools are omitted entirely under [readOnly] rather than advertised and
/// refused, so an agent never builds a plan around a tool that cannot run.
List<Map<String, dynamic>> mcpToolDescriptors({required bool readOnly}) => [
      for (final tool in _descriptors)
        if (!readOnly || McpToolNames.read.contains(tool['name']))
          Map<String, dynamic>.from(tool),
    ];

/// The input schema of [tool], or null when there is no such tool.
Map<String, dynamic>? mcpInputSchema(String tool) {
  for (final descriptor in _descriptors) {
    if (descriptor['name'] == tool) {
      return descriptor['inputSchema'] as Map<String, dynamic>;
    }
  }
  return null;
}

/// Check [args] against the declared schema of [tool].
///
/// Returns one readable message per problem, empty when the call is well
/// formed. Hand-written because this server owns its protocol layer; it
/// understands exactly the JSON Schema constructs [_descriptors] uses and
/// nothing more, so a descriptor reaching for anything else is a bug here
/// rather than a silently unchecked argument.
List<String> validateToolArgs(String tool, Map<String, Object?> args) {
  final schema = mcpInputSchema(tool);
  if (schema == null) return ['Unknown tool "$tool".'];

  final properties =
      (schema['properties'] as Map<String, dynamic>?) ?? const {};
  final required = (schema['required'] as List<dynamic>?) ?? const [];
  final problems = <String>[];

  for (final name in required) {
    if (!args.containsKey(name) || args[name] == null) {
      problems.add('Missing required argument "$name".');
    }
  }

  for (final entry in args.entries) {
    final spec = properties[entry.key] as Map<String, dynamic>?;
    if (spec == null) {
      problems.add(
        'Unknown argument "${entry.key}". Expected any of: '
        '${properties.keys.join(', ')}.',
      );
      continue;
    }

    final value = entry.value;
    // A null for a declared property reads as "not supplied"; required-ness is
    // already covered above, so there is nothing further to check.
    if (value == null) continue;

    switch (spec['type'] as String) {
      case 'string':
        if (value is! String) {
          problems.add('"${entry.key}" must be a string.');
          break;
        }
        final minLength = spec['minLength'] as int?;
        if (minLength != null && value.length < minLength) {
          problems.add('"${entry.key}" must not be empty.');
        }
      case 'integer':
        if (value is! int) {
          problems.add('"${entry.key}" must be an integer.');
          break;
        }
        final min = spec['minimum'] as int?;
        final max = spec['maximum'] as int?;
        if (min != null && value < min) {
          problems.add('"${entry.key}" must be at least $min.');
        }
        if (max != null && value > max) {
          problems.add('"${entry.key}" must be at most $max.');
        }
      case 'boolean':
        if (value is! bool) {
          problems.add('"${entry.key}" must be true or false.');
        }
    }
  }

  return problems;
}

const Map<String, dynamic> _readOnlyHint = {'readOnlyHint': true};

/// The tool table.
///
/// Ids in and out are always `worldId` UUIDs, never the local autoincrement
/// row id: row ids are assigned per device, so an agent that noted one down
/// would be pointing at a different task — or nothing — on the user's other
/// machine.
const List<Map<String, dynamic>> _descriptors = [
  {
    'name': McpToolNames.searchTasks,
    'description':
        'Search the outline for tasks whose title or note body contains every '
            'word in the query. Returns matching tasks with a snippet and the '
            'path of ancestor titles.',
    'annotations': _readOnlyHint,
    'inputSchema': {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'minLength': 1,
          'description':
              'Text to find. All whitespace-separated words must appear.',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': McpLimits.maxSearchLimit,
          'default': McpLimits.defaultSearchLimit,
          'description': 'Maximum number of results.',
        },
      },
      'required': ['query'],
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.getTree,
    'description':
        'Read the outline structure as nested tasks. Returns ids and titles; '
            'a node cut off by the depth or size limit is marked truncated, '
            'which is the cue to call again with that node as rootId.',
    'annotations': _readOnlyHint,
    'inputSchema': {
      'type': 'object',
      'properties': {
        'rootId': {
          'type': 'string',
          'description':
              'worldId of the task to start from. Omit for the top level.',
        },
        'depth': {
          'type': 'integer',
          'minimum': 1,
          'maximum': McpLimits.maxTreeDepth,
          'default': McpLimits.defaultTreeDepth,
          'description': 'How many levels below the root to include.',
        },
        'includeContent': {
          'type': 'boolean',
          'default': false,
          'description':
              'Include each task note body as plain text. Expensive on large '
                  'trees; prefer noo_get_task for a single note.',
        },
      },
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.getTask,
    'description':
        'Read one task: its title, note body as plain text, ancestor path, '
            'children and attachment count. There is no done or completed '
            'flag in this outline — tasks are not checked off.',
    'annotations': _readOnlyHint,
    'inputSchema': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'worldId of the task.'},
      },
      'required': ['id'],
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.createTask,
    'description': 'Create a task, optionally under a parent and at a chosen '
        'position among its siblings.',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': 'Title of the new task.'},
        'parentId': {
          'type': 'string',
          'description':
              'worldId of the parent. Omit to create at the top level.',
        },
        'content': {
          'type': 'string',
          'description': 'Note body, as plain text.',
        },
        'afterId': {
          'type': 'string',
          'description':
              'worldId of the sibling to insert after. Omit to append last.',
        },
      },
      'required': ['title'],
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.updateTask,
    'description':
        'Change a task title or note body. Note bodies are rich text; writing '
            'content replaces the whole body with plain text, discarding any '
            'formatting and inline images, so a task that is not already plain '
            'is refused unless force is set. Check contentIsPlain from '
            'noo_get_task first.',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'worldId of the task.'},
        'title': {'type': 'string', 'description': 'New title.'},
        'content': {
          'type': 'string',
          'description':
              'Replace the whole note body with this plain text. Cannot be '
                  'combined with appendContent.',
        },
        'appendContent': {
          'type': 'string',
          'description':
              'Append this plain text to the end of the note body. Cannot be '
                  'combined with content.',
        },
        'force': {
          'type': 'boolean',
          'default': false,
          'description':
              'Permit a content write that flattens a formatted note.',
        },
      },
      'required': ['id'],
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.moveTask,
    'description':
        'Move a task to a different parent, a different position among its '
            'siblings, or both.',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'worldId of the task to move.'},
        'parentId': {
          'type': 'string',
          'description':
              'worldId of the new parent. Omit to keep the current parent.',
        },
        'moveToRoot': {
          'type': 'boolean',
          'default': false,
          'description':
              'Move to the top level. Cannot be combined with parentId.',
        },
        'afterId': {
          'type': 'string',
          'description':
              'worldId of the sibling to place it after. Omit to append last '
                  'among the new siblings.',
        },
      },
      'required': ['id'],
      'additionalProperties': false,
    },
  },
  {
    'name': McpToolNames.deleteTask,
    'description':
        'Delete a task and everything underneath it. The deletion cascades to '
            'the whole subtree, so check what is under the task first. This is '
            'a soft delete: the rows stay in the database and the user can '
            'recover them, so there is no need to warn about permanent loss. '
            'Refused when the subtree contains content the user has excluded '
            'from agent access.',
    'annotations': {'destructiveHint': true, 'idempotentHint': false},
    'inputSchema': {
      'type': 'object',
      'properties': {
        'id': {'type': 'string', 'description': 'worldId of the task.'},
        'confirm': {
          'type': 'boolean',
          'description':
              'Must be true. Deleting a task also deletes every task under it.',
        },
      },
      'required': ['id', 'confirm'],
      'additionalProperties': false,
    },
  },
];
