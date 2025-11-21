// js/hotelDashboard.js

let currentUser = null;
let currentProfile = null;

document.addEventListener("DOMContentLoaded", () => {
  initHotelDashboard();
});

async function initHotelDashboard() {
  // Event-Listener
  document
    .getElementById("login-form")
    .addEventListener("submit", handleLogin);
  document
    .getElementById("register-form")
    .addEventListener("submit", handleRegister);
  document
    .getElementById("logout-btn")
    .addEventListener("click", logoutAndReload);
  document
    .getElementById("hotel-form")
    .addEventListener("submit", handleHotelSave);
  document
    .getElementById("new-hotel-btn")
    .addEventListener("click", resetHotelForm);

  // Beim Laden direkt prüfen, ob schon eingeloggt
  await checkAuthAndLoad();
}

async function checkAuthAndLoad() {
  currentUser = await getCurrentUser();
  if (!currentUser) {
    showAuthSection();
    return;
  }

  currentProfile = await getCurrentUserProfile();
  if (!currentProfile || (currentProfile.role !== "hotel" && currentProfile.role !== "admin")) {
    alert(
      "Ihr Account hat keine Hotel-Rolle. Bitte wende dich an den Admin."
    );
    await supabaseClient.auth.signOut();
    showAuthSection();
    return;
  }

  showDashboardSection();
  await loadMyHotels();
}

function showAuthSection() {
  document.getElementById("auth-section").style.display = "";
  document.getElementById("dashboard-section").style.display = "none";
}

function showDashboardSection() {
  document.getElementById("auth-section").style.display = "none";
  document.getElementById("dashboard-section").style.display = "";
}

async function handleLogin(event) {
  event.preventDefault();
  const email = document.getElementById("login-email").value.trim();
  const password = document.getElementById("login-password").value;

  const { error } = await supabaseClient.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    alert("Login fehlgeschlagen: " + error.message);
    return;
  }

  await checkAuthAndLoad();
}

async function handleRegister(event) {
  event.preventDefault();
  const email = document.getElementById("register-email").value.trim();
  const password = document.getElementById("register-password").value;

  const { data, error } = await supabaseClient.auth.signUp({
    email,
    password,
  });

  if (error) {
    alert("Registrierung fehlgeschlagen: " + error.message);
    return;
  }

  const user = data.user;
  if (user) {
    // Profil als Hotel anlegen
    const { error: profileError } = await supabaseClient
      .from("profiles")
      .insert([{ id: user.id, role: "hotel" }]);

    if (profileError) {
      console.error("Fehler beim Anlegen des Profils:", profileError.message);
    }
  }

  alert(
    "Registrierung erfolgreich. Bitte prüfe ggf. deine E-Mails und logge dich danach ein."
  );
}

async function loadMyHotels() {
  const user = await getCurrentUser();
  if (!user) return;

  const { data, error } = await supabaseClient
    .from("hotels")
    .select("*")
    .eq("owner_user_id", user.id)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Fehler beim Laden deiner Hotels:", error.message);
    return;
  }

  renderMyHotelsList(data || []);
}

function renderMyHotelsList(hotels) {
  const container = document.getElementById("my-hotels-list");
  container.innerHTML = "";

  if (!hotels.length) {
    container.innerHTML =
      "<p>Du hast noch keine Hotels angelegt. Nutze das Formular unten.</p>";
    return;
  }

  hotels.forEach((hotel) => {
    const div = document.createElement("div");
    div.className = "hotel-list-item";

    div.innerHTML = `
      <h3>${escapeHtml(hotel.name || "")}</h3>
      <div>${escapeHtml(hotel.city || "")}, ${escapeHtml(
      hotel.country || ""
    )}</div>
      <div style="font-size:0.8rem; color:#555;">
        Status: <strong>${escapeHtml(hotel.status || "")}</strong>
      </div>
      <div id="hotel-stats-${hotel.id}" style="font-size:0.8rem; color:#555; margin-top:4px;">
        Statistiken werden geladen...
      </div>
      <div class="button-row" style="margin-top:6px;">
        <button class="btn secondary" data-hotel-id="${hotel.id}">
          Bearbeiten
        </button>
      </div>
    `;

    div
      .querySelector("button[data-hotel-id]")
      .addEventListener("click", () => fillHotelForm(hotel));

    container.appendChild(div);

    // Statistiken für dieses Hotel laden
    loadStatsForHotel(hotel.id);
  });
}

/**
 * Statistiken (Views & Affiliate-Klicks) für ein Hotel laden
 */
async function loadStatsForHotel(hotelId) {
  const idNum = parseInt(hotelId, 10);
  if (!idNum) return;

  try {
    // Gesamtanzahl Aufrufe (event_type = 'view')
    const {
      count: viewsCount,
      error: viewsError,
    } = await supabaseClient
      .from("hotel_events")
      .select("*", { count: "exact", head: true })
      .eq("hotel_id", idNum)
      .eq("event_type", "view");

    if (viewsError) {
      console.error("Fehler beim Laden der Views:", viewsError.message);
    }

    // Gesamtanzahl Buchungsklicks (event_type = 'affiliate_click')
    const {
      count: clicksCount,
      error: clicksError,
    } = await supabaseClient
      .from("hotel_events")
      .select("*", { count: "exact", head: true })
      .eq("hotel_id", idNum)
      .eq("event_type", "affiliate_click");

    if (clicksError) {
      console.error(
        "Fehler beim Laden der Affiliate-Klicks:",
        clicksError.message
      );
    }

    const statsEl = document.getElementById(`hotel-stats-${idNum}`);
    if (statsEl) {
      const v = viewsCount ?? 0;
      const c = clicksCount ?? 0;
      statsEl.textContent = `Aufrufe: ${v} · Buchungsklicks: ${c}`;
    }
  } catch (err) {
    console.error("Fehler beim Laden der Hotel-Statistiken:", err);
  }
}

function fillHotelForm(hotel) {
  document.getElementById("hotel-id").value = hotel.id;
  document.getElementById("hotel-name").value = hotel.name || "";
  document.getElementById("hotel-description").value =
    hotel.description || "";
  document.getElementById("hotel-country").value = hotel.country || "";
  document.getElementById("hotel-city").value = hotel.city || "";
  document.getElementById("hotel-address").value = hotel.address || "";
  document.getElementById("hotel-latitude").value =
    hotel.latitude != null ? hotel.latitude : "";
  document.getElementById("hotel-longitude").value =
    hotel.longitude != null ? hotel.longitude : "";
  document.getElementById("hotel-wifi-speed").value =
    hotel.wifi_speed_mbps != null ? hotel.wifi_speed_mbps : "";
  document.getElementById("hotel-workspace").checked =
    !!hotel.workspace_in_room;
  document.getElementById("hotel-coworking-on-site").checked =
    !!hotel.coworking_on_site;
  document.getElementById("hotel-longstay").checked =
    !!hotel.long_stay_possible;
  document.getElementById("hotel-longstay-min").value =
    hotel.long_stay_min_nights != null ? hotel.long_stay_min_nights : "";
  document.getElementById("hotel-affiliate-url").value =
    hotel.affiliate_url || "";
}

function resetHotelForm() {
  document.getElementById("hotel-id").value = "";
  document.getElementById("hotel-form").reset();
}

async function handleHotelSave(event) {
  event.preventDefault();
  const user = await getCurrentUser();
  if (!user) {
    alert("Nicht eingeloggt.");
    return;
  }

  const id = document.getElementById("hotel-id").value || null;
  const name = document.getElementById("hotel-name").value.trim();
  const description = document
    .getElementById("hotel-description")
    .value.trim();
  const country = document.getElementById("hotel-country").value.trim();
  const city = document.getElementById("hotel-city").value.trim();
  const address = document.getElementById("hotel-address").value.trim();
  const latitudeStr =
    document.getElementById("hotel-latitude").value.trim() || null;
  const longitudeStr =
    document.getElementById("hotel-longitude").value.trim() || null;
  const wifiSpeedStr =
    document.getElementById("hotel-wifi-speed").value.trim() || null;

  const workspace = document.getElementById("hotel-workspace").checked;
  const coworkingOnSite = document.getElementById(
    "hotel-coworking-on-site"
  ).checked;
  const longstay = document.getElementById("hotel-longstay").checked;
  const longstayMinStr =
    document.getElementById("hotel-longstay-min").value.trim() || null;
  const affiliateUrl = document
    .getElementById("hotel-affiliate-url")
    .value.trim();

  const payload = {
    owner_user_id: user.id,
    name,
    description,
    country,
    city,
    address,
    latitude: latitudeStr ? parseFloat(latitudeStr) : null,
    longitude: longitudeStr ? parseFloat(longitudeStr) : null,
    wifi_speed_mbps: wifiSpeedStr ? parseInt(wifiSpeedStr, 10) : null,
    workspace_in_room: workspace,
    coworking_on_site: coworkingOnSite,
    long_stay_possible: longstay,
    long_stay_min_nights: longstayMinStr ? parseInt(longstayMinStr, 10) : null,
    affiliate_url: affiliateUrl || null,
  };

  let error;
  if (id) {
    // Update
    const result = await supabaseClient
      .from("hotels")
      .update(payload)
      .eq("id", id);
    error = result.error;
  } else {
    // Neuer Eintrag, Status initial "pending"
    payload.status = "pending";
    const result = await supabaseClient.from("hotels").insert([payload]);
    error = result.error;
  }

  if (error) {
    alert("Fehler beim Speichern: " + error.message);
    return;
  }

  alert("Hotel gespeichert.");
  resetHotelForm();
  await loadMyHotels();
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
