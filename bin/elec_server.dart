
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:rpc/rpc.dart';

import 'package:elec/src/api/nepool_lmp.dart';

const String _API_PREFIX = '';
final ApiServer _apiServer = new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);

registerApis() async {
  DaLmp dalmp = new DaLmp();
  await dalmp.db.open();
  _apiServer.addApi(dalmp);
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new SyncFileLoggingHandler('myLogFile.txt'));
  if (stdout.hasTerminal)
  Logger.root.onRecord.listen(new LogPrintHandler());

  await registerApis();

  _apiServer.enableDiscoveryApi();

  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8080);
  server.listen(_apiServer.httpRequestHandler);
}

