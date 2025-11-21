// js/map.js

let map;
let markersLayer;
const markersByHotelId = {};
let initialHotelIdFromUrl = null;

document.addEventListener("DOMContentLoaded", () => {
  initMap();

  // hotelId aus der URL lesen (z.B. index.html?hotelId=123)
  const params = new URLSearchParams(window.location.search);
  initialHotelIdFromUrl = params.get("hotelId");

  const filterForm = document.getElementById("filter-form");
  const resetBtn = document.getElementById("reset-filter-btn");

  filterForm.addEventListener("submit", (e) => {
    e.preventDefault();
    // normale Filter-Anwendung: kein spezieller Fokus
    loadHotels();
  });

  resetBtn.addEventListener("click", () => {
    document.getElementById("filter-city").value = "";
    document.getElementById("filter-wifi-min").value = "";
    document.getElementById("filter-workspace").checked = false;
    document.getElementById("filter-coworking-onsite").checked = false;
    document.getElementById("filter-coworking-nearby").checked = false;
    document.getElementById("filter-longstay").checked = false;
    document.getElementById("filter-longstay-max").value = "";
    loadHotels();
  });

  const hotelList = document.getElementById("hotel-list");
  hotelList.addEventListener("click", (e) => {
    const btn = e.target.closest("button[data-hotel-id]");
    if (!btn) return;
    const hotelId = btn.getAttribute("data-hotel-id");
    focusHotelOnMap(hotelId);
    scrollHotelIntoView(hotelId);
  });

  // Globaler Click-Handler für alle Affiliate-Links (Karte + Liste)
  document.addEventListener("click", handleGlobalAffiliateLinkClick);

  // Erstes Laden: wenn hotelId in der URL vorhanden ist, Fokus setzen
  if (initialHotelIdFromUrl) {
    loadHotels(initialHotelIdFromUrl);
    // danach nicht nochmal automatisch fokussieren
    initialHotelIdFromUrl = null;
  } else {
    loadHotels();
  }
});

function initMap() {
  map = L.map("map").setView([20, 0], 2); // Weltkarte

  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "&copy; OpenStreetMap-Mitwirkende",
  }).addTo(map);

  markersLayer = L.layerGroup().addTo(map);
}

async function loadHotels(focusHotelId) {
  const city = document.getElementById("filter-city").value.trim();
  const wifiMinStr = document.getElementById("filter-wifi-min").value;
  const wifiMin = wifiMinStr ? parseInt(wifiMinStr, 10) : null;

  const onlyWorkspace = document.getElementById("filter-workspace").checked;
  const coworkingOnsite = document.getElementById(
    "filter-coworking-onsite"
  ).checked;
  const coworkingNearby = document.getElementById(
    "filter-coworking-nearby"
  ).checked;
  const onlyLongstay = document.getElementById("filter-longstay").checked;
  const longstayMaxStr = document
    .getElementById("filter-longstay-max")
    .value.trim();
  const longstayMax = longstayMaxStr ? parseInt(longstayMaxStr, 10) : null;

  let query = supabaseClient.from("hotels").select("*").eq("status", "approved");

  if (city) {
    query = query.ilike("city", `%${city}%`);
  }

  if (wifiMin !== null && !Number.isNaN(wifiMin)) {
    query = query.gte("wifi_speed_mbps", wifiMin);
  }

  if (onlyWorkspace) {
    query = query.eq("workspace_in_room", true);
  }

  if (coworkingOnsite && coworkingNearby) {
    query = query.or("coworking_on_site.eq.true,coworking_nearby.eq.true");
  } else if (coworkingOnsite) {
    query = query.eq("coworking_on_site", true);
  } else if (coworkingNearby) {
    query = query.eq("coworking_nearby", true);
  }

  if (onlyLongstay) {
    query = query.eq("long_stay_possible", true);
    if (longstayMax !== null && !Number.isNaN(longstayMax)) {
      query = query.lte("long_stay_min_nights", longstayMax);
    }
  }

  const { data, error } = await query.order("created_at", { ascending: false });

  if (error) {
    console.error("Fehler beim Laden der Hotels:", error.message);
    return;
  }

  const hotels = data || [];
  renderHotelsOnMap(hotels);
  renderHotelList(hotels);

  if (focusHotelId) {
    focusHotelOnMap(String(focusHotelId));
    scrollHotelIntoView(String(focusHotelId));
  }
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
      ${
        hotel.wifi_speed_mbps != null
          ? "📶 WLAN ca. " +
            escapeHtml(hotel.wifi_speed_mbps) +
            " Mbit/s<br/>"
          : ""
      }
      ${hotel.workspace_in_room ? "💻 Arbeitsplatz im Zimmer<br/>" : ""}
      ${hotel.coworking_on_site ? "🏢 Coworking im Hotel<br/>" : ""}
      ${hotel.coworking_nearby ? "🏢 Coworking in der Nähe<br/>" : ""}
      ${
        hotel.long_stay_possible
          ? "📅 Langzeitaufenthalte möglich" +
            (hotel.long_stay_min_nights
              ? " (ab " +
                escapeHtml(hotel.long_stay_min_nights) +
                " Tagen)"
              : "") +
            "<br/>"
          : ""
      }
      ${
        hotel.affiliate_url
          ? `<br/><a
                href="${encodeURI(hotel.affiliate_url)}"
                data-affiliate-link="1"
                data-hotel-id="${hotel.id}"
             >Jetzt buchen</a>`
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
    div.dataset.hotelId = hotel.id;

    const badges = [];
    if (hotel.workspace_in_room) badges.push("Arbeitsplatz im Zimmer");
    if (hotel.coworking_on_site) badges.push("Coworking im Hotel");
    if (hotel.coworking_nearby) badges.push("Coworking in der Nähe");
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
        ${
          hotel.wifi_speed_mbps != null
            ? "WLAN ca. " +
              escapeHtml(hotel.wifi_speed_mbps) +
              " Mbit/s<br/>"
            : ""
        }
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
            ? `<a class="btn"
                  data-affiliate-link="1"
                  data-hotel-id="${hotel.id}"
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

  // View-Event tracken
  trackHotelEvent(hotelId, "view");
}

/**
 * Scrollt das Hotel in der Liste in den sichtbaren Bereich
 * und hebt es kurz hervor.
 */
function scrollHotelIntoView(hotelId) {
  const listEl = document.getElementById("hotel-list");
  if (!listEl) return;
  const item = listEl.querySelector(
    `.hotel-list-item[data-hotel-id="${hotelId}"]`
  );
  if (!item) return;

  item.scrollIntoView({ behavior: "smooth", block: "start" });
  item.classList.add("highlight");
  setTimeout(() => {
    item.classList.remove("highlight");
  }, 2000);
}

/**
 * Globaler Click-Handler für Links mit data-affiliate-link
 * – trackt Klick & öffnet Link in neuem Tab
 */
function handleGlobalAffiliateLinkClick(event) {
  const link = event.target.closest("a[data-affiliate-link]");
  if (!link) return;

  event.preventDefault();

  const hotelId = link.getAttribute("data-hotel-id");
  const url = link.getAttribute("href");

  if (hotelId) {
    trackHotelEvent(hotelId, "affiliate_click");
  }

  if (url) {
    window.open(url, "_blank", "noopener");
  }
}

/**
 * Tracking-Event an Supabase senden.
 * eventType: 'view' | 'affiliate_click'
 */
async function trackHotelEvent(hotelId, eventType) {
  const idNum = parseInt(hotelId, 10);
  if (!idNum || !eventType) return;

  try {
    const { error } = await supabaseClient
      .from("hotel_events")
      .insert([{ hotel_id: idNum, event_type: eventType }]);

    if (error) {
      console.error("Fehler beim Tracking-Event:", error.message);
    }
  } catch (err) {
    console.error("Fehler beim Senden des Tracking-Events:", err);
  }
}

// einfache HTML-Escape-Funktion
function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
