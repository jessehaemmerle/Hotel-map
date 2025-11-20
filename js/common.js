// js/common.js
// Gemeinsamer Supabase-Client + Auth-Helfer

// Supabase wird über das CDN als globales Objekt "supabase" bereitgestellt
const { createClient } = supabase;

// Ein gemeinsamer Client für die gesamte App
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Aktuell eingeloggten User holen
 */
async function getCurrentUser() {
  const { data, error } = await supabaseClient.auth.getUser();
  if (error) {
    console.error("Fehler beim Laden des Users:", error.message);
    return null;
  }
  return data.user;
}

/**
 * Profil des Users (Rolle etc.) holen
 * Tabelle: profiles (id = auth.users.id, role = 'hotel' | 'admin')
 */
async function getCurrentUserProfile() {
  const user = await getCurrentUser();
  if (!user) return null;

  const { data, error } = await supabaseClient
    .from("profiles")
    .select("id, role")
    .eq("id", user.id)
    .single();

  if (error) {
    console.error("Fehler beim Laden des Profils:", error.message);
    return null;
  }

  return data;
}

/**
 * Benutzer abmelden
 */
async function logoutAndReload() {
  await supabaseClient.auth.signOut();
  window.location.reload();
}
