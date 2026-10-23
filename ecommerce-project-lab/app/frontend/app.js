const statusBox = document.querySelector('#status');
const productsBox = document.querySelector('#products');

async function loadProducts() {
  try {
    const response = await fetch('/api/products');
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    productsBox.innerHTML = data.products.map(product => `
      <article class="card">
        <span class="category">${product.category}</span>
        <h2>${product.name}</h2>
        <p class="price">$${product.price.toFixed(2)}</p>
        <p class="muted">Product #${product.id}</p>
      </article>`).join('');
    statusBox.textContent = `Loaded ${data.products.length} products through the Kubernetes /api proxy.`;
    statusBox.className = 'status success';
  } catch (error) {
    statusBox.textContent = `Could not load products: ${error.message}`;
    statusBox.className = 'status error';
  }
}

loadProducts();