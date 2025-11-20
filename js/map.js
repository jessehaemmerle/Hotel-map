// js/map.js

let map;
let markersLayer;
const markersByHotelId = {};

document.addEventListener("DOMContentLoaded", () => {
  initMap();

  const filterForm = document.getElementById("filter-form");
  const resetBtn = document.getElementById("reset-filter-btn");

  filterForm.addEventListener("submit", (e) => {
    e.preventDefault();
    loadHotels();
  });

  resetBtn.addEventListener("click", () => {
    document.getElementById("filter-city").value = "";
    document.getElementById("filter-workspace").checked = false;
    document.getElementById("filter-coworking").checked = false;
    document.getElementById("filter-longstay").checked = false;
    loadHotels();
  });

  const hotelList = document.getElementById("hotel-list");
  hotelList.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-hotel-id]");
    if (!btn) return;
    const hotelId = btn.getAttribute("data-hotel-id");
    focusHotelOnMap(hotelId);
  });

  loadHotels();
});

function initMap() {
  map = L.map("map").setView([20, 0], 2); // Weltkarte

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "&copy; OpenStreetMap-Mitwirkende",
  }).addTo(map);

  markersLayer = L.layerGroup().addTo(map);
}

async function loadHotels() {
  const city = document.getElementById("filter-city").value.trim();
  const onlyWorkspace = document.getElementById("filter-workspace").checked;
  const onlyCoworking = document.getElementById("filter-coworking").checked;
  const onlyLongstay = document.getElementById("filter-longstay").checked;

  let query = supabaseClient.from("hotels").select("*").eq("status", "approved");

  if (city) {
    query = query.ilike("city", `%${city}%`);
  }
  if (onlyWorkspace) {
    query = query.eq("workspace_in_room", true);
  }
  if (onlyCoworking) {
    query = query.or("coworking_on_site.eq.true,coworking_nearby.eq.true");
  }
  if (onlyLongstay) {
    query = query.eq("long_stay_possible", true);
  }

  const { data, error } = await query.order("created_at", { ascending: false });

  if (error) {
    console.error("Fehler beim Laden der Hotels:", error.message);
    return;
  }

  renderHotelsOnMap(data || []);
  renderHotelList(data || []);
}

function renderHotelsOnMap(hotels) {
  markersLayer.clearLayers();
  Object.keys(markersByHotelId).forEach((key) => delete markersByHotelId[key]);

  const bounds = [];

  hotels.forEach((hotel) => {
    if (hotel.latitude == null || hotel.longitude == null) {
      return;
    }

    const marker = L.marker([hotel.latitude, hotel.longitude]);
    markersLayer.addLayer(marker);

    const popupHtml = `
      <strong>${escapeHtml(hotel.name || "")}</strong><br/>
      ${escapeHtml(hotel.city || "")}, ${escapeHtml(hotel.country || "")}<br/>
      ${hotel.workspace_in_room ? "💻 Arbeitsplatz im Zimmer<br/>" : ""}
      ${hotel.coworking_on_site ? "🏢 Coworking im Hotel<br/>" : ""}
      ${
        hotel.long_stay_possible
          ? "📅 Langzeitaufenthalte möglich<br/>"
          : ""
      }
      ${
        hotel.affiliate_url
          ? `<br/><a href="${encodeURI(
              hotel.affiliate_url
            )}" target="_blank" rel="noopener">Jetzt buchen</a>`
          : ""
      }
    `;

    marker.bindPopup(popupHtml);
    markersByHotelId[hotel.id] = marker;
    bounds.push([hotel.latitude, hotel.longitude]);
  });

  if (bounds.length > 0) {
    const latLngBounds = L.latLngBounds(bounds);
    map.fitBounds(latLngBounds, { padding: [40, 40] });
  }
}

function renderHotelList(hotels) {
  const listEl = document.getElementById("hotel-list");
  listEl.innerHTML = "";

  if (hotels.length === 0) {
    listEl.innerHTML =
      "<p>Keine Hotels gefunden. Passe ggf. die Filter an.</p>";
    return;
  }

  hotels.forEach((hotel) => {
    const div = document.createElement("div");
    div.className = "hotel-list-item";

    const badges = [];
    if (hotel.workspace_in_room) badges.push("Arbeitsplatz im Zimmer");
    if (hotel.coworking_on_site) badges.push("Coworking im Hotel");
    if (hotel.long_stay_possible) badges.push("Langzeitaufenthalt");

    div.innerHTML = `
      <h3>${escapeHtml(hotel.name || "")}</h3>
      <div>${escapeHtml(hotel.city || "")}, ${escapeHtml(
      hotel.country || ""
    )}</div>
      <div style="margin: 4px 0;">
        ${badges
          .map((b) => `<span class="badge">${escapeHtml(b)}</span>`)
          .join(" ")}
      </div>
      <div style="font-size: 0.8rem; color:#555; margin:4px 0;">
        ${escapeHtml(hotel.description || "").slice(0, 140)}${
      (hotel.description || "").length > 140 ? "..." : ""
    }
      </div>
      <div class="button-row">
        <button class="btn secondary" data-hotel-id="${hotel.id}">
          Auf Karte zeigen
        </button>
        ${
          hotel.affiliate_url
            ? `<a class="btn" target="_blank" rel="noopener"
                  href="${encodeURI(hotel.affiliate_url)}">Jetzt buchen</a>`
            : ""
        }
      </div>
    `;

    listEl.appendChild(div);
  });
}

function focusHotelOnMap(hotelId) {
  const marker = markersByHotelId[hotelId];
  if (!marker) return;
  const latLng = marker.getLatLng();
  map.setView(latLng, 14);
  marker.openPopup();
}

// einfache HTML-Escape-Funktion
function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
