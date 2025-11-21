// js/adminPanel.js

// 1) Geheimer Token für den Admin-Link.
//    -> HIER einen eigenen zufälligen String einsetzen
//    Beispiel-Aufruf im Browser:
//    https://deine-domain.tld/admin-panel.html?k=MEIN_GEHEIMER_CODE
const SECRET_LINK_TOKEN = "DEIN_GEHEIMER_LINKCODE";

// Globale Variablen für Admin-User & -Profil
let adminUser = null;
let adminProfile = null;

document.addEventListener("DOMContentLoaded", () => {
  // ZUERST prüfen, ob der geheime Link stimmt
  if (!checkSecretToken()) {
    return; // nichts weiter machen
  }

  // Event Listener
  document
    .getElementById("admin-login-form")
    .addEventListener("submit", handleAdminLogin);

  document
    .getElementById("admin-logout-btn")
    .addEventListener("click", logoutAndReload);

  document
    .getElementById("refresh-hotels-btn")
    .addEventListener("click", loadAllHotels);

  document
    .getElementById("refresh-profiles-btn")
    .addEventListener("click", loadAllProfiles);

  const statsBtn = document.getElementById("refresh-stats-btn");
  if (statsBtn) {
    statsBtn.addEventListener("click", loadStatsSummary);
  }

  // Event-Delegation für Tabellen
  document
    .getElementById("admin-hotels-tbody")
    .addEventListener("click", handleHotelActionClick);

  document
    .getElementById("admin-profiles-tbody")
    .addEventListener("click", handleProfileActionClick);

  // Prüfen, ob bereits ein Admin eingeloggt ist
  checkAdminAuthAndLoad();
});

/**
 * Prüft, ob der Query-Parameter ?k=... dem SECRET_LINK_TOKEN entspricht.
 * Falls nicht, wird ein 404-ähnlicher Screen angezeigt.
 */
function checkSecretToken() {
  const params = new URLSearchParams(window.location.search);
  const token = params.get("k");

  const wrapper = document.getElementById("admin-wrapper");
  const denied = document.getElementById("secret-denied");

  if (token !== SECRET_LINK_TOKEN) {
    // Falscher oder fehlender Token -> "404"
    if (wrapper) wrapper.style.display = "none";
    if (denied) denied.style.display = "block";
    return false;
  }

  // Token korrekt -> Admin-Oberfläche aktivieren
  if (wrapper) wrapper.style.display = "block";
  if (denied) denied.style.display = "none";
  return true;
}

/**
 * Prüft Supabase-Login und Admin-Rolle.
 */
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
  await loadAllProfiles();
  await loadStatsSummary();
}

function showAdminAuth() {
  document.getElementById("admin-auth-section").style.display = "";
  document.getElementById("admin-dashboard-section").style.display = "none";
}

function showAdminDashboard() {
  document.getElementById("admin-auth-section").style.display = "none";
  document.getElementById("admin-dashboard-section").style.display = "";
}

/**
 * Login-Handler für den Admin.
 */
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

/* ===========================
   HOTELS – VERWALTUNG
   =========================== */

async function loadAllHotels() {
  const { data, error } = await supabaseClient
    .from("hotels")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Fehler beim Laden aller Hotels:", error.message);
    alert("Fehler beim Laden der Hotels.");
    return;
  }

  renderAdminHotels(data || []);
}

function renderAdminHotels(hotels) {
  const tbody = document.getElementById("admin-hotels-tbody");
  tbody.innerHTML = "";

  hotels.forEach((hotel) => {
    const tr = document.createElement("tr");

    const shortId = hotel.id != null ? String(hotel.id) : "";
    const ownerShort =
      hotel.owner_user_id != null
        ? String(hotel.owner_user_id).slice(0, 8) + "…"
        : "";

    tr.innerHTML = `
      <td>${escapeHtml(shortId)}</td>
      <td>${escapeHtml(hotel.name || "")}</td>
      <td>${escapeHtml(hotel.city || "")}, ${escapeHtml(
      hotel.country || ""
    )}</td>
      <td>${escapeHtml(hotel.status || "")}</td>
      <td style="font-size:0.75rem;">${escapeHtml(ownerShort)}</td>
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
}

/**
 * Event-Handler für Buttons in der Hotel-Tabelle (Approve/Disable/Reject).
 */
async function handleHotelActionClick(event) {
  const btn = event.target.closest("button[data-action][data-id]");
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

/* ===========================
   PROFILES / BENUTZER – VERWALTUNG
   =========================== */

async function loadAllProfiles() {
  const { data, error } = await supabaseClient
    .from("profiles")
    .select("id, role")
    .order("role", { ascending: true });

  if (error) {
    console.error("Fehler beim Laden der Profile:", error.message);
    alert("Fehler beim Laden der Benutzer.");
    return;
  }

  renderAdminProfiles(data || []);
}

function renderAdminProfiles(profiles) {
  const tbody = document.getElementById("admin-profiles-tbody");
  tbody.innerHTML = "";

  profiles.forEach((profile) => {
    const shortId =
      profile.id != null ? String(profile.id).slice(0, 8) + "…" : "";

    const roleLabel = profile.role || "(keine Rolle)";

    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td style="font-size:0.75rem;">${escapeHtml(shortId)}</td>
      <td>${escapeHtml(roleLabel)}</td>
      <td>
        <div class="button-row">
          <button class="btn secondary" data-action="make-hotel" data-id="${
            profile.id
          }">Als Hotel markieren</button>
          <button class="btn secondary" data-action="make-admin" data-id="${
            profile.id
          }">Als Admin markieren</button>
        </div>
      </td>
    `;

    tbody.appendChild(tr);
  });
}

/**
 * Event-Handler für Buttons in der Profile-Tabelle (Rollen setzen).
 */
async function handleProfileActionClick(event) {
  const btn = event.target.closest("button[data-action][data-id]");
  if (!btn) return;

  const action = btn.getAttribute("data-action");
  const id = btn.getAttribute("data-id");
  let newRole;

  if (action === "make-hotel") {
    newRole = "hotel";
  } else if (action === "make-admin") {
    newRole = "admin";
  } else {
    return;
  }

  const { error } = await supabaseClient
    .from("profiles")
    .update({ role: newRole })
    .eq("id", id);

  if (error) {
    alert("Fehler beim Setzen der Rolle: " + error.message);
    return;
  }

  await loadAllProfiles();
}

/* ===========================
   STATISTIKEN – TOP-HOTELS
   =========================== */

/**
 * Lädt Statistiken aus hotel_events (letzte 30 Tage),
 * aggregiert sie nach Hotel und zeigt eine Top-Liste.
 */
async function loadStatsSummary() {
  const tbody = document.getElementById("admin-stats-tbody");
  if (!tbody) return;

  tbody.innerHTML = `
    <tr><td colspan="6">Lade Statistiken...</td></tr>
  `;

  // Zeitraum: letzte 30 Tage
  const now = new Date();
  const from = new Date(now.getTime());
  from.setDate(from.getDate() - 30);
  const fromIso = from.toISOString();

  // 1) Events holen (nur hotel_id + event_type)
  const { data: events, error } = await supabaseClient
    .from("hotel_events")
    .select("hotel_id, event_type")
    .gte("created_at", fromIso);

  if (error) {
    console.error("Fehler beim Laden der Events:", error.message);
    tbody.innerHTML = `
      <tr><td colspan="6">Fehler beim Laden der Statistiken.</td></tr>
    `;
    return;
  }

  if (!events || events.length === 0) {
    tbody.innerHTML = `
      <tr><td colspan="6">Keine Daten im gewählten Zeitraum.</td></tr>
    `;
    return;
  }

  // 2) In JS aggregieren: Views & Klicks pro Hotel
  const statsByHotelId = {};
  for (const ev of events) {
    const hid = ev.hotel_id;
    if (!statsByHotelId[hid]) {
      statsByHotelId[hid] = { views: 0, clicks: 0 };
    }
    if (ev.event_type === "view") {
      statsByHotelId[hid].views += 1;
    } else if (ev.event_type === "affiliate_click") {
      statsByHotelId[hid].clicks += 1;
    }
  }

  const hotelIds = Object.keys(statsByHotelId).map((id) => parseInt(id, 10));
  if (hotelIds.length === 0) {
    tbody.innerHTML = `
      <tr><td colspan="6">Keine Daten im gewählten Zeitraum.</td></tr>
    `;
    return;
  }

  // 3) Hotel-Metadaten holen (Name, Ort)
  const { data: hotels, error: hotelsError } = await supabaseClient
    .from("hotels")
    .select("id, name, city, country")
    .in("id", hotelIds);

  if (hotelsError) {
    console.error("Fehler beim Laden der Hotels für Stats:", hotelsError.message);
    tbody.innerHTML = `
      <tr><td colspan="6">Fehler beim Laden der Hotel-Daten.</td></tr>
    `;
    return;
  }

  const hotelMetaById = {};
  (hotels || []).forEach((h) => {
    hotelMetaById[h.id] = h;
  });

  // 4) Liste aufbauen und nach Klicks sortieren (absteigend)
  const rows = [];
  for (const hidStr of Object.keys(statsByHotelId)) {
    const hid = parseInt(hidStr, 10);
    const meta = hotelMetaById[hid] || {};
    const stats = statsByHotelId[hid];

    const views = stats.views || 0;
    const clicks = stats.clicks || 0;
    const ctr = views > 0 ? (clicks / views) * 100 : 0;

    rows.push({
      hotelId: hid,
      name: meta.name || "(unbekanntes Hotel)",
      city: meta.city || "",
      country: meta.country || "",
      views,
      clicks,
      ctr,
    });
  }

  rows.sort((a, b) => b.clicks - a.clicks || b.views - a.views);

  // 5) Rendern
  tbody.innerHTML = "";
  if (rows.length === 0) {
    tbody.innerHTML = `
      <tr><td colspan="6">Keine Daten im gewählten Zeitraum.</td></tr>
    `;
    return;
  }

  rows.forEach((row, index) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${index + 1}</td>
      <td>${escapeHtml(row.name)}</td>
      <td>${escapeHtml(row.city)}, ${escapeHtml(row.country)}</td>
      <td>${row.views}</td>
      <td>${row.clicks}</td>
      <td>${row.ctr.toFixed(1)}</td>
    `;
    tbody.appendChild(tr);
  });
}

/* ===========================
   Hilfsfunktion: HTML escapen
   =========================== */

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
