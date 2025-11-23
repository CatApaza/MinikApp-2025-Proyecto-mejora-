class Order {
  constructor({
    id = "",
    nombreCliente = "Desconocido",
    correoCliente = "N/A",
    estado = "Pendiente",
    total = 0,
    fecha = null,
    direccion = "",
    items = [],
    metodoPago = "",
    metodoEntrega = "",
    userId = "",
    repartidorId = null,
  } = {}) {
    this.id = id;
    this.nombreCliente = nombreCliente;
    this.correoCliente = correoCliente;
    this.estado = estado;
    this.total = total;
    this.fecha = fecha;
    this.direccion = direccion;
    this.items = items;
    this.metodoPago = metodoPago;
    this.metodoEntrega = metodoEntrega;
    this.userId = userId;
    this.repartidorId = repartidorId;
  }

  getTotalFormateado() {
    return `S/ ${this.total.toFixed(2)}`;
  }

  getFechaFormateada() {
    if (!this.fecha) return "Fecha no disponible";
    return new Date(this.fecha.seconds * 1000).toLocaleDateString();
  }
}

export default Order;

