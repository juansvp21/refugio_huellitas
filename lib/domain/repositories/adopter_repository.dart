import 'package:refugio_huellitas/domain/models/adopter.dart';

abstract class AdopterRepository {
  Future<List<Adopter>> getAllAdopters();
  Future<Adopter> addAdopter(Adopter adopter);
  Future<Adopter> updateAdopter(Adopter adopter);
  Future<void> removeAdopter(String adopterId);
}
