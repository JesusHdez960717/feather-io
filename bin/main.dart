import 'package:winter/winter.dart';

void main() async {
  ObjectMapper om = ObjectMapper(serializers: [], deserializers: []);

  await Winter.start(
    config: ServerConfig(port: 8080),
    context: BuildContext(objectMapper: om),
    router: WinterRouter(
      routes: [
        Route(
          path: '/test',
          method: HttpMethod.get,
          handler: (request) async {
            return ResponseEntity.ok(body: 'Test OK');
          },
        ),
      ],
    ),
  );
}
