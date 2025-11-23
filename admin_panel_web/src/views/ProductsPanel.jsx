import React, { useState, useEffect, useRef } from "react";
import Product from "../models/product";
import "./ProductPanel.css";
import {
  obtenerProductos,
  agregarProducto,
  actualizarProducto,
  eliminarProducto,
} from "../controllers/productcontroller";

const ProductsPanel = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [form, setForm] = useState({
    id: "",
    nombre: "",
    precio: "",
    stock: "",
    imageUrl: "",
    categoria: "",
  });

  const [categoriaFiltro, setCategoriaFiltro] = useState("Todos");

  const [snackbar, setSnackbar] = useState({ mensaje: "", tipo: "" }); // Snackbar

  const categorias = [
    "Todos",
    "Lácteos",
    "Dulces",
    "Bebidas",
    "Verduras",
    "Panes",
    "Frutas",
    "Menestras",
    "Carnes",
    "Aseo",
    "Otros"
  ];

  const formRef = useRef(null);

  // Función para mostrar snackbar
  const mostrarSnackbar = (mensaje, tipo = "success", duracion = 3000) => {
    setSnackbar({ mensaje, tipo });
    setTimeout(() => {
      setSnackbar({ mensaje: "", tipo: "" });
    }, duracion);
  };

  useEffect(() => {
    const unsubscribe = obtenerProductos(
      (productsData) => {
        setProducts(productsData);
        setLoading(false);
      },
      (err) => {
        setError("Error al obtener productos: " + err.message);
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (form.id) {
        await actualizarProducto(form.id, {
          nombre: form.nombre,
          precio: parseFloat(form.precio),
          stock: parseInt(form.stock, 10),
          imageUrl: form.imageUrl,
          categoria: form.categoria,
        });
        mostrarSnackbar("Producto actualizado correctamente ✅");
      } else {
        const newProduct = new Product(
          null,
          form.nombre,
          parseFloat(form.precio),
          parseInt(form.stock, 10),
          form.imageUrl,
          form.categoria
        );
        await agregarProducto(newProduct);
        mostrarSnackbar("Producto agregado correctamente ✅");
      }
      setForm({
        id: "",
        nombre: "",
        precio: "",
        stock: "",
        imageUrl: "",
        categoria: "",
      });
    } catch (e) {
      setError("Error al guardar el producto.");
      mostrarSnackbar("Error al guardar el producto ❌", "error");
    }
  };

  const handleEdit = (product) => {
    setForm({
      id: product.id,
      nombre: product.nombre,
      precio: product.precio,
      stock: product.stock,
      imageUrl: product.imageUrl,
      categoria: product.categoria || "",
    });

    if (formRef.current) {
      formRef.current.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  const handleDelete = async (productId) => {
    try {
      await eliminarProducto(productId);
      mostrarSnackbar("Producto eliminado correctamente ✅");
    } catch (e) {
      setError("Error al eliminar el producto.");
      mostrarSnackbar("Error al eliminar el producto ❌", "error");
    }
  };

  const productosFiltrados =
    categoriaFiltro === "Todos"
      ? products
      : products.filter((p) => p.categoria === categoriaFiltro);

  if (loading) {
    return (
      <div className="loading-container">
        <p>Cargando productos...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <p>{error}</p>
      </div>
    );
  }

  return (
    <div>
      {/* Formulario */}
      <div className="panel-section" ref={formRef}>
        <h2 className="section-title">Gestión de Productos</h2>
        <form onSubmit={handleSubmit} className="form-grid">
          <input
            type="text"
            name="nombre"
            value={form.nombre}
            onChange={handleChange}
            placeholder="Nombre del Producto"
            className="input-field"
            required
          />
          <input
            type="number"
            name="precio"
            value={form.precio}
            onChange={handleChange}
            placeholder="Precio"
            step="0.01"
            className="input-field"
            required
          />
          <input
            type="number"
            name="stock"
            value={form.stock}
            onChange={handleChange}
            placeholder="Stock"
            className="input-field"
            required
          />
          <input
            type="text"
            name="imageUrl"
            value={form.imageUrl}
            onChange={handleChange}
            placeholder="URL de la imagen"
            className="input-field"
            required
          />
          <select
            name="categoria"
            value={form.categoria}
            onChange={handleChange}
            className="input-field"
            required
          >
            <option value="">Selecciona una categoría</option>
            {categorias
              .filter((c) => c !== "Todos")
              .map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
          </select>

          <button type="submit" className="submit-button">
            {form.id ? "Actualizar Producto" : "Agregar Producto"}
          </button>
        </form>
      </div>

      {/* Lista de productos */}
      <div className="panel-section">
        <h2 className="section-title">Lista de Productos</h2>

        <div className="filter-section">
          <label htmlFor="filtroCategoria">Filtrar por categoría: </label>
          <select
            id="filtroCategoria"
            value={categoriaFiltro}
            onChange={(e) => setCategoriaFiltro(e.target.value)}
            className="input-field"
          >
            {categorias.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>

        <div className="product-list">
          {productosFiltrados.map((product) => (
            <div key={product.id} className="product-card">
              <img
                src={product.imageUrl}
                alt={product.nombre}
                className="product-image"
              />
              <div className="product-info">
                <h3 className="product-name">{product.nombre}</h3>
                <p className="product-price">
                  Precio: ${product.precio.toFixed(2)}
                </p>
                <p className="product-stock">Stock: {product.stock}</p>
                <p className="product-category">
                  Categoría: {product.categoria}
                </p>
                <div className="product-actions">
                  <button
                    onClick={() => handleEdit(product)}
                    className="edit-button"
                  >
                    Editar
                  </button>
                  <button
                    onClick={() => handleDelete(product.id)}
                    className="delete-button"
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {productosFiltrados.length === 0 && !loading && (
          <p className="no-products-message">
            No hay productos en esta categoría.
          </p>
        )}
      </div>

      {/* Snackbar */}
      {snackbar.mensaje && (
        <div className={`snackbar ${snackbar.tipo}`}>{snackbar.mensaje}</div>
      )}
    </div>
  );
};

export default ProductsPanel;
