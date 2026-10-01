class ModeloPartido {
  final String id;
  final String titulo;
  final String disciplina;
  final String icono;
  final String ubicacion;
  final String fechaHora;
  final int cuposTotales;
  final int cuposOcupados;
  final String nivel;
  final String organizadorNombre;
  final bool soyOrganizador;
  final bool estoyUnido;

  ModeloPartido({
    required this.id,
    required this.titulo,
    required this.disciplina,
    required this.icono,
    required this.ubicacion,
    required this.fechaHora,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.nivel,
    required this.organizadorNombre,
    this.soyOrganizador = false,
    this.estoyUnido = false,
  });

  int get cuposRestantes => cuposTotales - cuposOcupados;
  bool get estaLleno => cuposRestantes <= 0;
}
