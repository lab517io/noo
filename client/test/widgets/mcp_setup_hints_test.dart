import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/widgets/dialogs/mcp_setup_hints.dart';

/// The snippets are the whole point of the MCP tab: a user copies one and it
/// either works or it silently does not. A broken interpolation looks entirely
/// plausible on screen, so it is checked here rather than by eye.
void main() {
  const port = 8737;
  const token = 'deadbeef';

  for (final client in McpClientHint.values) {
    group(mcpClientLabel(client), () {
      final snippet = mcpSetupSnippet(client, port: port, token: token);

      test('carries the live endpoint and token', () {
        expect(snippet, contains('http://127.0.0.1:$port/mcp'));
        expect(snippet, contains(token));
      });

      test('has no unfilled placeholder', () {
        expect(snippet, isNot(contains('null')));
        // A literal `$` is legitimate — OpenCode's block declares `$schema` —
        // so what is checked is an interpolation that failed to run.
        expect(snippet, isNot(contains(r'${')));
      });

      test('is labelled with somewhere to put it', () {
        expect(mcpSetupTarget(client), isNotEmpty);
        expect(mcpClientLabel(client), isNotEmpty);
      });
    });
  }

  test('the OpenCode snippet is valid JSON with the right header', () {
    final decoded = jsonDecode(
      mcpSetupSnippet(McpClientHint.openCode, port: port, token: token),
    ) as Map<String, dynamic>;

    final server = decoded['mcp']['noo'] as Map<String, dynamic>;
    expect(server['type'], 'remote');
    expect(server['url'], 'http://127.0.0.1:$port/mcp');
    expect(server['headers']['Authorization'], 'Bearer $token');
    // Without this OpenCode reads the server's 401 as an invitation to start
    // an OAuth registration it cannot finish.
    expect(server['oauth'], isFalse);
  });

  test('the Codex snippet declares the server table and the header', () {
    final snippet =
        mcpSetupSnippet(McpClientHint.codexCli, port: port, token: token);
    expect(snippet, contains('[mcp_servers.noo]'));
    expect(snippet, contains('http_headers = { Authorization = "Bearer $token" }'));
  });

  test('the Claude Code snippet puts every flag before the server name', () {
    final snippet =
        mcpSetupSnippet(McpClientHint.claudeCode, port: port, token: token);
    expect(snippet, startsWith('claude mcp add '));
    expect(
      snippet.indexOf('--transport http'),
      lessThan(snippet.indexOf(' noo ')),
    );
  });

  test('the stdio bridge header has no space after the colon', () {
    // mcp-remote takes the whole Name:Value as one argument; a space there
    // splits it on several shells.
    final snippet = mcpStdioBridgeSnippet(port: port, token: token);
    expect(snippet, contains('"Authorization:Bearer $token"'));
  });
}
