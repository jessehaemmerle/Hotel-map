// js/adminDashboard.js

let adminUser = null;
let adminProfile = null;

document.addEventListener("DOMContentLoaded", () => {
  document
    .getElementById("admin-login-form")
    .addEventListener("submit", handleAdminLogin);
  document
    .getElementById("admin-logout-btn")
    .addEventListener("click", logoutAndReload);

  checkAdminAuthAndLoad();
});

async function checkAdminAuthAndLoad() {
  adminUser = await getCurrentUser();
  if (!adminUser) {
    showAdminAuth();
    return;
  }

  adminProfile = await getCurrentUserProfile();
  if (!adminProfile || adminProfile.role !== "admin") {
    alert("Kein Admin-Konto. Zugriff verweigert.");
    await supabaseClient.auth.signOut();
    showAdminAuth();
    return;
  }

  showAdminDashboard();
  await loadAllHotels();
}

function showAdminAuth() {
  document.getElementById("admin-auth-section").style.display = "";
  document.getElementById("admin-dashboard-section").style.display = "none";
}

function showAdminDashboard() {
  document.getElementById("admin-auth-section").style.display = "none";
  document.getElementById("admin-dashboard-section").style.display = "";
}

async function handleAdminLogin(event) {
  event.preventDefault();
  const email = document.getElementById("admin-email").value.trim();
  const password = document.getElementById("admin-password").value;

  const { error } = await supabaseClient.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    alert("Login fehlgeschlagen: " + error.message);
    return;
  }

  await checkAdminAuthAndLoad();
}

async function loadAllHotels() {
  const { data, error } = await supabaseClient
    .from("hotels")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Fehler beim Laden aller Hotels:", error.message);
    return;
  }

  renderAdminHotels(data || []);
}

function renderAdminHotels(hotels) {
  const tbody = document.getElementById("admin-hotels-tbody");
  tbody.innerHTML = "";

  hotels.forEach((hotel) => {
    const tr = document.createElement("tr");

    tr.innerHTML = `
      <td>${escapeHtml(hotel.name || "")}</td>
      <td>${escapeHtml(hotel.city || "")}, ${escapeHtml(
      hotel.country || ""
    )}</td>
      <td>${escapeHtml(hotel.status || "")}</td>
      <td style="font-size:0.75rem;">${escapeHtml(
        hotel.owner_user_id || ""
      )}</td>
      <td>
        <div class="button-row">
          <button class="btn secondary" data-action="approve" data-id="${
            hotel.id
          }">Freischalten</button>
          <button class="btn secondary" data-action="disable" data-id="${
            hotel.id
          }">Deaktivieren</button>
          <button class="btn danger" data-action="reject" data-id="${
            hotel.id
          }">Ablehnen</button>
        </div>
      </td>
    `;

    tbody.appendChild(tr);
  });

  tbody.addEventListener("click", handleAdminActionClick);
}

async function handleAdminActionClick(event) {
  const btn = event.target.closest("button[data-action]");
  if (!btn) return;

  const action = btn.getAttribute("data-action");
  const id = btn.getAttribute("data-id");
  let newStatus;

  if (action === "approve") {
    newStatus = "approved";
  } else if (action === "disable") {
    newStatus = "disabled";
  } else if (action === "reject") {
    newStatus = "rejected";
  } else {
    return;
  }

  const { error } = await supabaseClient
    .from("hotels")
    .update({ status: newStatus })
    .eq("id", id);

  if (error) {
    alert("Fehler beim Aktualisieren des Status: " + error.message);
    return;
  }

  await loadAllHotels();
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
