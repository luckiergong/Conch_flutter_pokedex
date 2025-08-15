import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pokedex/app.dart';
import 'package:pokedex/core/network.dart';
import 'package:pokedex/data/repositories/item_repository.dart';
import 'package:pokedex/data/repositories/pokemon_repository.dart';
import 'package:pokedex/data/source/github/github_datasource.dart';
import 'package:pokedex/data/source/local/local_datasource.dart';
import 'package:pokedex/states/theme/theme_cubit.dart';
import 'package:pokedex/states/item/item_bloc.dart';
import 'package:pokedex/states/pokemon/pokemon_bloc.dart';
import 'package:flutter_conch_plugin/annotation/patch_scope.dart';

import 'package:flutter_conch_loader/flutter_conch_loader.dart';

@PatchScope()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 推荐使用shilpy平台配置
  var fileLoader = ShiplyFileLoader(ResHubParams(
      appVersion: "1.0.0",
      deviceId: "12345",
      appId: "6db6d7936d",
      appKey: "a19b7300-e6f0-45f4-80d7-9a1986812f0b",
      env: "online",
      resId: "conch_test_pokedex",
      awaitNetData: true));
  // 初始化基础能力
  // 初始化完成之后的操作
  ConchLoader.getInstance().init(
    showDebugTag: true,
    customLoadPageReporter: (name, code, message) {
      print("加载结果 name: $name, code: $code,message:$message");
    },
    onLoadingBuilder: () {
      return Scaffold(
        body: Center(
          child: Text("初始化加载样式……"),
        ),
      );
    },
  );
  // 绑定具体加载逻辑
  ConchLoader.getInstance().bindFileLoader(fileLoader, isPreLoad: true);
  ConchLoader.getInstance();

  await mainInner();
}

mainInner() async {
  await LocalDataSource.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: [
        ///
        /// Services
        ///
        RepositoryProvider<NetworkManager>(
          create: (context) => NetworkManager(),
        ),

        ///
        /// Data sources
        ///
        RepositoryProvider<LocalDataSource>(
          create: (context) => LocalDataSource(),
        ),
        RepositoryProvider<GithubDataSource>(
          create: (context) => GithubDataSource(context.read<NetworkManager>()),
        ),

        ///
        /// Repositories
        ///
        RepositoryProvider<PokemonRepository>(
          create: (context) => PokemonDefaultRepository(
            localDataSource: context.read<LocalDataSource>(),
            githubDataSource: context.read<GithubDataSource>(),
          ),
        ),

        RepositoryProvider<ItemRepository>(
          create: (context) => ItemDefaultRepository(
            localDataSource: context.read<LocalDataSource>(),
            githubDataSource: context.read<GithubDataSource>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          ///
          /// BLoCs
          ///
          BlocProvider<PokemonBloc>(
            create: (context) => PokemonBloc(context.read<PokemonRepository>()),
          ),
          BlocProvider<ItemBloc>(
            create: (context) => ItemBloc(context.read<ItemRepository>()),
          ),

          ///
          /// Theme Cubit
          ///
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(),
          )
        ],
        child: const PokedexApp(),
      ),
    ),
  );
}
