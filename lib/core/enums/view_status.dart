/// Ekranların 4 Durum Kalkanı için ortak yükleme durumu.
/// (initial → loading → loaded / failure)
enum ViewStatus {
  initial,
  loading,
  loaded,
  failure;

  bool get isLoading => this == ViewStatus.initial || this == ViewStatus.loading;
}
