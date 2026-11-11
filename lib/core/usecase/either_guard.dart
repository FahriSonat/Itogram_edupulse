import 'dart:async';

import 'package:dartz/dartz.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Repository çağrısını çalıştırır; istisnaları Domain [Failure]'larına çevirir.
/// UseCase'lerdeki tekrar eden try/catch bloklarını ortadan kaldırır.
Future<Either<Failure, T>> guardFailure<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } on ExpiredQrPinException catch (e) {
    return Left(ExpiredCodeFailure(e.message));
  } on UnauthorizedRoleException catch (e) {
    return Left(PermissionDeniedFailure(e.message));
  } catch (e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    // attendance datasource'u kendi ExpiredQrPinException sınıfını tanımlıyor.
    if (e.runtimeType.toString() == 'ExpiredQrPinException') return Left(ExpiredCodeFailure(text));
    if (text.contains('permission-denied')) return const Left(PermissionDeniedFailure());
    return Left(ServerFailure(text));
  }
}

/// Repository akışını `Either` akışına çevirir; hata olayı akışı sonlandırmaz.
/// `transform` kullanıldığı için dinleyici iptal edilince kaynak abonelik de kapanır.
Stream<Either<Failure, T>> guardStream<T>(Stream<T> source) {
  return source.transform(
    StreamTransformer<T, Either<Failure, T>>.fromHandlers(
      handleData: (data, sink) => sink.add(Right(data)),
      handleError: (error, _, sink) =>
          sink.add(Left(ServerFailure(error.toString().replaceFirst('Exception: ', '')))),
    ),
  );
}
