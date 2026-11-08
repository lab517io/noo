/// Copy-pasteable setup for the coding agents that can reach this server.
///
/// Pure functions rather than widgets, for two reasons: they can be tested
/// without pumping a dialog, and these three CLIs change their configuration
/// keys considerably faster than this app ships — keeping them in one file
/// makes re-checking against current documentation a single small diff.
library;

enum McpClientHint { claudeCode, codexCli, openCode }

String mcpClientLabel(McpClientHint client) => switch (client) {
      McpClientHint.claudeCode => 'Claude Code',
      McpClientHint.codexCli => 'Codex CLI',
      McpClientHint.openCode => 'OpenCode',
    };

/// Where the snippet goes — a shell, or a particular config file.
String mcpSetupTarget(McpClientHint client) => switch (client) {
      McpClientHint.claudeCode => 'Run this in a terminal:',
      McpClientHint.codexCli => r'Add to ~/.codex/config.toml:',
      McpClientHint.openCode => 'Add to opencode.json:',
    };

/// A note under the snippet, or empty when there is nothing worth saying.
String mcpSetupNote(McpClientHint client) => switch (client) {
      McpClientHint.claudeCode =>
        'Scoped to your user, so the outline is available in every project.',
      McpClientHint.codexCli =>
        'To keep the token out of the file, replace http_headers with '
            'bearer_token_env_var = "NOO_MCP_TOKEN" and set that variable in '
            'your shell.',
      McpClientHint.openCode =>
        'oauth: false matters — without it OpenCode reads this server\'s 401 '
            'as an invitation to start an OAuth registration it cannot finish.',
    };

String mcpEndpointUrl(int port) => 'http://127.0.0.1:$port/mcp';

/// The configuration for [client], with the live port and token filled in.
String mcpSetupSnippet(
  McpClientHint client, {
  required int port,
  required String token,
}) {
  final url = mcpEndpointUrl(port);

  return switch (client) {
    // Every flag has to precede the server name.
    McpClientHint.claudeCode =>
      'claude mcp add --scope user --transport http noo $url '
          '--header "Authorization: Bearer $token"',
    McpClientHint.codexCli => '[mcp_servers.noo]\n'
        'url = "$url"\n'
        'http_headers = { Authorization = "Bearer $token" }',
    McpClientHint.openCode => '{\n'
        '  "\$schema": "https://opencode.ai/config.json",\n'
        '  "mcp": {\n'
        '    "noo": {\n'
        '      "type": "remote",\n'
        '      "url": "$url",\n'
        '      "enabled": true,\n'
        '      "oauth": false,\n'
        '      "headers": { "Authorization": "Bearer $token" }\n'
        '    }\n'
        '  }\n'
        '}',
  };
}

/// Bridge for an agent that speaks only stdio.
///
/// The space after the colon is missing on purpose: mcp-remote takes the whole
/// `Name:Value` as one argument, and adding one splits it on several shells.
String mcpStdioBridgeSnippet({required int port, required String token}) =>
    'npx -y mcp-remote ${mcpEndpointUrl(port)} '
    '--header "Authorization:Bearer $token"';
