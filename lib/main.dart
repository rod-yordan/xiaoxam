import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xiaoxa/providers/auth_provider.dart';
import 'package:xiaoxa/providers/banner_provider.dart';
import 'package:xiaoxa/providers/categoria_provider.dart';
import 'package:xiaoxa/providers/checkout_provider.dart';
import 'package:xiaoxa/providers/favoritos_provider.dart';
import 'package:xiaoxa/providers/generos_provider.dart';
import 'package:xiaoxa/screens/catalogo_parte2.dart';
import 'package:xiaoxa/screens/catalogo_parte3.dart';
import 'package:xiaoxa/screens/chat.dart';
import 'package:xiaoxa/screens/compra_exitosa.dart';
import 'package:xiaoxa/screens/informacion_compra.dart';
import 'package:xiaoxa/screens/resumen_compra.dart';
import 'package:xiaoxa/screens/informacion_cuenta.dart';
import 'package:xiaoxa/screens/pedidos.dart';
import 'package:provider/provider.dart';
import 'package:xiaoxa/providers/carrito_provider.dart';
import 'package:xiaoxa/screens/main_layout.dart';
import 'package:xiaoxa/screens/busqueda.dart';
import 'package:xiaoxa/screens/carrito.dart';
import 'package:xiaoxa/screens/catalogo_parte1.dart';
import 'package:xiaoxa/screens/cupones.dart';
import 'package:xiaoxa/screens/detalles_producto.dart';
import 'package:xiaoxa/screens/favoritos.dart';
import 'package:xiaoxa/screens/iniciar_sesion.dart';
import 'package:xiaoxa/screens/pagina_principal.dart';
import 'package:xiaoxa/screens/registro_usuario.dart';
import 'package:xiaoxa/screens/perfil.dart';
import 'package:xiaoxa/services/pref_service.dart';
import 'package:pusher_beams/pusher_beams.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefService = PrefService();
  await prefService.init();

  const instanceID = 'c5190994-49a1-4d86-ab48-70fca28a4704';

  try {
    await PusherBeams.instance.start(instanceID);
    await PusherBeams.instance.addDeviceInterest('ofertas');
    await PusherBeams.instance.addDeviceInterest('lanzamientos');

    final isLoggedIn = prefService.getLoginStatus();
    if (isLoggedIn) {
      final userId = prefService.getUserId();
      if (userId != null) {
        await PusherBeams.instance.addDeviceInterest('carrito-$userId');
      }
    }
  } catch (e) {
    // Errores
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarritoProvider()),
        ChangeNotifierProvider(create: (_) => FavoritosProvider()),
        ChangeNotifierProvider(create: (_) => GenerosProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'Lucky',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFED1C24),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const PaginaPrincipal(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalogo',
              name: 'catalogo',
              builder: (context, state) => const CatalogoParte1(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cupones',
              name: 'cupones',
              builder: (context, state) => const Cupones(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favoritos',
              name: 'favoritos',
              builder: (context, state) => const Favoritos(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cuenta',
              name: 'cuenta',
              redirect: (context, state) {
                if (state.fullPath == '/cuenta/registroUsuario') {
                  return null;
                }

                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                if (!authProvider.isLoggedIn) {
                  return '/cuenta/iniciarSesion';
                }
                return '/cuenta/perfil';
              },
              routes: [
                GoRoute(
                  path: 'perfil',
                  name: 'perfil',
                  builder: (context, state) => const Perfil(),
                ),
                GoRoute(
                  path: 'iniciarSesion',
                  name: 'login',
                  builder: (context, state) => const IniciarSesion(),
                ),
                GoRoute(
                  path: 'registroUsuario',
                  name: 'registro',
                  builder: (context, state) => const RegistroUsuario(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/carrito',
      name: 'carrito',
      builder: (context, state) => const Carrito(),
    ),
    GoRoute(
      path: '/busqueda',
      name: 'busqueda',
      builder: (context, state) => const Busqueda(),
    ),
    GoRoute(
      path: '/detallesProducto',
      name: 'detalle',
      builder: (context, state) {
        final producto = state.extra as Map<String, dynamic>;
        return DetallesProducto(producto: producto);
      },
    ),
    GoRoute(
      path: '/informacionCompra',
      name: 'informacionCompra',
      builder: (context, state) => const InformacionCompra(),
    ),
    GoRoute(
      path: '/resumen-compra',
      name: 'resumenCompra',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ResumenCompra(data: extra);
      },
    ),
    GoRoute(
      path: '/compraExitosa',
      name: 'compraExitosa',
      builder: (context, state) {
        return CompraExitosa(extra: state.extra as Map<String, dynamic>?);
      },
    ),
    GoRoute(
      path: '/mis-pedidos',
      name: 'misPedidos',
      builder: (context, state) => const MisPedidos(),
    ),
    GoRoute(
      path: '/catalogo-parte2',
      name: 'catalogoParte2',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CatalogoParte2(
          genero: extra['genero'],
          generoId: extra['generoId'],
        );
      },
    ),
    GoRoute(
      path: '/catalogo-parte3',
      name: 'catalogoParte3',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CatalogoParte3(
          categoria: extra['categoria'],
          categoriaId: extra['categoriaId'],
          genero: extra['genero'],
          generoId: extra['generoId'],
        );
      },
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const Chat(),
    ),
    GoRoute(
      path: '/informacion-cuenta',
      name: 'informacionCuenta',
      builder: (context, state) => const InformacionCuenta(),
    ),
  ],
);
