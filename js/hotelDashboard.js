// js/hotelDashboard.js

let currentUser = null;
let currentProfile = null;
let myHotelsRaw = [];

document.addEventListener("DOMContentLoaded", () => {
  initHotelDashboard();
});

async function initHotelDashboard() {
  // Event-Listener Auth & Formular
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

  // Filter im Dashboard (Vorschau wie öffentliche Suche)
  const dashFilterForm = document.getElementById("dashboard-filter-form");
  if (dashFilterForm) {
    dashFilterForm.addEventListener("submit", (event) => {
      event.preventDefault();
      applyAndRenderMyHotelFilters();
    });
  }

  const dashFilterResetBtn = document.getElementById(
    "dashboard-filter-reset-btn"
  );
  if (dashFilterResetBtn) {
    dashFilterResetBtn.addEventListener("click", () => {
      resetDashboardFilters();
      applyAndRenderMyHotelFilters();
    });
  }

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
  if (
    !currentProfile ||
    (currentProfile.role !== "hotel" && currentProfile.role !== "admin")
  ) {
    alert("Ihr Account hat keine Hotel-Rolle. Bitte wende dich an den Admin.");
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

  myHotelsRaw = data || [];
  const hotelsToRender = applyMyHotelFilters();
  renderMyHotelsList(hotelsToRender);
}

function renderMyHotelsList(hotels) {
  const container = document.getElementById("my-hotels-list");
  container.innerHTML = "";

  if (!hotels.length) {
    container.innerHTML =
      "<p>Du hast keine Hotels, die auf diese Filter passen. Passe ggf. die Filter an oder lege ein neues Hotel an.</p>";
    return;
  }

  hotels.forEach((hotel) => {
    const div = document.createElement("div");
    div.className = "hotel-list-item";

    const badges = [];
    if (hotel.wifi_speed_mbps != null) {
      badges.push("WLAN ~ " + escapeHtml(hotel.wifi_speed_mbps) + " Mbit/s");
    }
    if (hotel.workspace_in_room) badges.push("Arbeitsplatz im Zimmer");
    if (hotel.coworking_on_site) badges.push("Coworking im Hotel");
    if (hotel.coworking_nearby) badges.push("Coworking in der Nähe");
    if (hotel.long_stay_possible) {
      if (hotel.long_stay_min_nights != null) {
        badges.push(
          "Langzeit ab " + escapeHtml(hotel.long_stay_min_nights) + " Tagen"
        );
      } else {
        badges.push("Langzeitaufenthalt");
      }
    }

    div.innerHTML = `
      <h3>${escapeHtml(hotel.name || "")}</h3>
      <div>${escapeHtml(hotel.city || "")}, ${escapeHtml(
      hotel.country || ""
    )}</div>
      <div style="margin:4px 0;">
        ${badges
          .map((b) => `<span class="badge">${escapeHtml(b)}</span>`)
          .join(" ")}
      </div>
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
        <a
          class="btn"
          href="index.html?hotelId=${hotel.id}"
          target="_blank"
          rel="noopener"
        >
          Vorschau
        </a>
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
 * Filter wie in der öffentlichen Suche – angewendet auf eigene Hotels.
 */
function applyMyHotelFilters() {
  if (!Array.isArray(myHotelsRaw)) return [];

  const wifiMinStr =
    document.getElementById("dash-filter-wifi-min")?.value || "";
  const wifiMin = wifiMinStr ? parseInt(wifiMinStr, 10) : null;

  const onlyWorkspace =
    document.getElementById("dash-filter-workspace")?.checked || false;
  const coworkingOnsite =
    document.getElementById("dash-filter-coworking-onsite")?.checked || false;
  const coworkingNearby =
    document.getElementById("dash-filter-coworking-nearby")?.checked || false;
  const onlyLongstay =
    document.getElementById("dash-filter-longstay")?.checked || false;

  const longstayMaxStr =
    document.getElementById("dash-filter-longstay-max")?.value.trim() || "";
  const longstayMax = longstayMaxStr ? parseInt(longstayMaxStr, 10) : null;

  return myHotelsRaw.filter((hotel) => {
    if (wifiMin !== null && !Number.isNaN(wifiMin)) {
      const speed = hotel.wifi_speed_mbps;
      if (speed == null || speed < wifiMin) return false;
    }

    if (onlyWorkspace && !hotel.workspace_in_room) return false;

    if (coworkingOnsite && coworkingNearby) {
      if (!hotel.coworking_on_site && !hotel.coworking_nearby) return false;
    } else if (coworkingOnsite) {
      if (!hotel.coworking_on_site) return false;
    } else if (coworkingNearby) {
      if (!hotel.coworking_nearby) return false;
    }

    if (onlyLongstay) {
      if (!hotel.long_stay_possible) return false;
      if (longstayMax !== null && !Number.isNaN(longstayMax)) {
        const minNights = hotel.long_stay_min_nights;
        if (minNights != null && minNights > longstayMax) return false;
      }
    }

    return true;
  });
}

function applyAndRenderMyHotelFilters() {
  const filtered = applyMyHotelFilters();
  renderMyHotelsList(filtered);
}

function resetDashboardFilters() {
  const wifiSelect = document.getElementById("dash-filter-wifi-min");
  if (wifiSelect) wifiSelect.value = "";

  const idsToUncheck = [
    "dash-filter-workspace",
    "dash-filter-coworking-onsite",
    "dash-filter-coworking-nearby",
    "dash-filter-longstay",
  ];
  idsToUncheck.forEach((id) => {
    const el = document.getElementById(id);
    if (el) el.checked = false;
  });

  const longstayMaxInput = document.getElementById("dash-filter-longstay-max");
  if (longstayMaxInput) longstayMaxInput.value = "";
}

/**
 * Statistiken (Views & Affiliate-Klicks) für ein Hotel laden
 */
async function loadStatsForHotel(hotelId) {
  const idNum = parseInt(hotelId, 10);
  if (!idNum) return;

  try {
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
  const nearbyEl = document.getElementById("hotel-coworking-nearby");
  if (nearbyEl) {
    nearbyEl.checked = !!hotel.coworking_nearby;
  }
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
  const nearbyEl = document.getElementById("hotel-coworking-nearby");
  const coworkingNearby = nearbyEl ? nearbyEl.checked : false;
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
    coworking_nearby: coworkingNearby,
    long_stay_possible: longstay,
    long_stay_min_nights: longstayMinStr ? parseInt(longstayMinStr, 10) : null,
    affiliate_url: affiliateUrl || null,
  };

  let error;
  if (id) {
    const result = await supabaseClient
      .from("hotels")
      .update(payload)
      .eq("id", id);
    error = result.error;
  } else {
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
