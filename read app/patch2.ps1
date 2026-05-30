# patch2.ps1 — second-pass modifications to read app/index.html

$path = "C:\Users\User\Desktop\myapp\read app\index.html"
$text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$text = $text.Replace("`r`n", "`n")

function RemoveBlock($t, $startMarker, $endMarker) {
    $s = $t.IndexOf($startMarker)
    if ($s -lt 0) { Write-Warning "RemoveBlock: start not found: $($startMarker.Substring(0,[Math]::Min(40,$startMarker.Length)))"; return $t }
    $e = $t.IndexOf($endMarker, $s)
    if ($e -lt 0) { Write-Warning "RemoveBlock: end not found: $($endMarker.Substring(0,[Math]::Min(40,$endMarker.Length)))"; return $t }
    return $t.Remove($s, $e - $s)
}
function ExactReplace($t, $old, $new) {
    $o = $old.Replace("`r`n", "`n").Trim()
    $n = $new.Replace("`r`n", "`n").Trim()
    $i = $t.IndexOf($o)
    if ($i -lt 0) { Write-Warning "ExactReplace: not found: $($o.Substring(0,[Math]::Min(50,$o.Length)))"; return $t }
    return $t.Remove($i, $o.Length).Insert($i, $n)
}

# ═══════════════════════════════════════════════════════
# TASK 1 addendum — rename data-tag-filter CSS attribute
# ═══════════════════════════════════════════════════════
$text = $text.Replace(".chip[data-tag-filter]{cursor:pointer}", ".chip[data-tag-click]{cursor:pointer}")

# ═══════════════════════════════════════════════════════
# TASK 1 addendum — remove filter-related CSS
# ═══════════════════════════════════════════════════════

# btn-filter + filter-bar CSS
$text = $text.Replace(
    ".btn-filter{display:inline-flex;align-items:center;gap:5px;padding:6px 14px;border-radius:20px;cursor:pointer;font-family:inherit;font-size:13px;border:1px solid var(--border);background:var(--card);color:var(--textMid);transition:all .12s}`n.btn-filter:active{transform:scale(.96)}`n.filter-bar{margin-bottom:10px}",
    "")

# filter-badge (keep sort-sel)
$text = $text.Replace("`n.filter-badge{font-weight:700;color:var(--text)}", "")

# flt-section, flt-chips, flt-clear-btn CSS — remove from flt-section to end of flt-clear-btn:active
$text = RemoveBlock $text "`n.flt-section{" "`n.chip[data-tag"

# ═══════════════════════════════════════════════════════
# TASK 2 — State variables
# ═══════════════════════════════════════════════════════

# Remove flt* vars, keep searchQ
$text = $text.Replace(
    "let fltSpice='', fltLength='', fltTime='', fltTags={}, searchQ='';",
    "let searchQ='';")

# Rename currentSort -> sortOrder
$text = $text.Replace("let currentSort = 'new-desc';", "let sortOrder = 'new-desc';")
$text = $text.Replace("currentSort = e.target.value;", "sortOrder = e.target.value;")

# Remove _filterHistoryPushed declaration
$text = $text.Replace("`nlet _filterHistoryPushed = false;", "")

# ═══════════════════════════════════════════════════════
# TASK 2 — Remove filter functions
# ═══════════════════════════════════════════════════════

# Block A: renderFilters() + isMobile() — remove from renderFilters to openTagSheet
$text = RemoveBlock $text "`nfunction renderFilters()" "`nfunction openTagSheet("

# Block B: openFilterSheet through bindFilterSheetEvents — remove to renderGrid
$text = RemoveBlock $text "`nfunction openFilterSheet()" "`nfunction renderGrid()"

# ═══════════════════════════════════════════════════════
# TASK 2 — Update getFiltered (remove flt* checks, rename sort var)
# ═══════════════════════════════════════════════════════
$oldGF = @'
function getFiltered() {
  let result = books.filter(b => {
    if (fltSpice  && b.spice !==fltSpice)  return false;
    if (fltLength && b.length!==fltLength) return false;
    if (fltTime && b.time !== fltTime) return false;
    for (const [gk,tags] of Object.entries(fltTags)) {
      if (tags?.length && !tags.some(t=>b.types.includes(t))) return false;
    }
    if (searchQ) {
      const q = searchQ.toLowerCase();
      const inTitle  = b.title.toLowerCase().includes(q);
      const inAuthor = b.author.toLowerCase().includes(q);
      const inAtk    = (b.attackType||'').toLowerCase().includes(q);
      const inTypes  = (b.types||[]).some(t => t.toLowerCase().includes(q));
      const inTime   = (b.time||'').toLowerCase().includes(q);
      const inLength = (b.length||'').toLowerCase().includes(q);
      const inSpice  = (b.spice||'').toLowerCase().includes(q);
      if (!inTitle && !inAuthor && !inAtk && !inTypes && !inTime && !inLength && !inSpice) return false;
    }
    return true;
  });
  switch (currentSort) {
    case 'new-asc':    result = result.slice().sort((a,b) => a.id - b.id); break;
    case 'stars-desc': result = result.slice().sort((a,b) => b.stars - a.stars); break;
    case 'stars-asc':  result = result.slice().sort((a,b) => a.stars - b.stars); break;
    default:           result = result.slice().sort((a,b) => b.id - a.id); break;
  }
  return result;
}
'@
$newGF = @'
function getFiltered() {
  let result = books.filter(b => {
    if (searchQ) {
      const q = searchQ.toLowerCase();
      const inTitle  = b.title.toLowerCase().includes(q);
      const inAuthor = b.author.toLowerCase().includes(q);
      const inAtk    = (b.attackType||'').toLowerCase().includes(q);
      const inTypes  = (b.types||[]).some(t => t.toLowerCase().includes(q));
      const inTime   = (b.time||'').toLowerCase().includes(q);
      const inLength = (b.length||'').toLowerCase().includes(q);
      const inSpice  = (b.spice||'').toLowerCase().includes(q);
      if (!inTitle && !inAuthor && !inAtk && !inTypes && !inTime && !inLength && !inSpice) return false;
    }
    return true;
  });
  switch (sortOrder) {
    case 'new-asc':    result = result.slice().sort((a,b) => a.id - b.id); break;
    case 'stars-desc': result = result.slice().sort((a,b) => b.stars - a.stars); break;
    case 'stars-asc':  result = result.slice().sort((a,b) => a.stars - b.stars); break;
    default:           result = result.slice().sort((a,b) => b.id - a.id); break;
  }
  return result;
}
'@
$text = ExactReplace $text $oldGF $newGF

# ═══════════════════════════════════════════════════════
# TASK 2 — Remove renderFilters() call sites
# ═══════════════════════════════════════════════════════
# In openTagSheet: currentPage=1; renderFilters(); renderGrid();
$text = $text.Replace("currentPage=1; renderFilters(); renderGrid();", "currentPage=1; renderGrid();")
# renderGrid(); renderFilters(); (two variants)
$text = $text.Replace("renderGrid(); renderFilters();", "renderGrid();")
$text = $text.Replace("renderFilters(); renderGrid();", "renderGrid();")
# Standalone initial call
$text = $text.Replace("`nrenderFilters();`n", "`n")

# ═══════════════════════════════════════════════════════
# TASK 2 — Remove btn-filter-sheet event listener
# ═══════════════════════════════════════════════════════
$text = $text.Replace(
    "`ndocument.getElementById('btn-filter-sheet').addEventListener('click', openFilterSheet);",
    "")

# ═══════════════════════════════════════════════════════
# TASK 2 — Remove global chip click delegation (old data-tag-filter)
# ═══════════════════════════════════════════════════════
$oldDelegation = @'
document.addEventListener('click', e => {
  const chip = e.target.closest('[data-tag-filter]');
  if (!chip) return;
  e.stopPropagation();
  const tag = chip.dataset.tagFilter;
  if (!tag) return;
  const overlay = document.getElementById('modal-overlay');
  if (overlay && overlay.classList.contains('open')) {
    _closeModalVisual();
    _modalHistoryPushed = false;
  }
  searchQ = tag;
  document.getElementById('search-inp').value = tag;
  currentPage = 1;
  renderGrid();
  window.scrollTo({top:0, behavior:'smooth'});
});
'@
$oldDelegation = $oldDelegation.Replace("`r`n","`n").Trim()
$idx = $text.IndexOf($oldDelegation)
if ($idx -ge 0) { $text = $text.Remove($idx, $oldDelegation.Length) }
else { Write-Warning "Global chip delegation not found" }

# ═══════════════════════════════════════════════════════
# TASK 2 — Update popstate handler (remove filter sheet part)
# ═══════════════════════════════════════════════════════
$oldPopstate = @'
window.addEventListener('popstate', () => {
  const isFilterSheetOpen = document.getElementById('filter-sheet')?.classList.contains('open');
  if (isFilterSheetOpen) {
    _filterHistoryPushed = false;
    document.getElementById('filter-sheet-overlay')?.classList.remove('open');
    document.getElementById('filter-sheet')?.classList.remove('open');
    return;
  }
  const formView = document.getElementById('view-form');
  const overlay  = document.getElementById('modal-overlay');
  const isFormOpen  = !formView.classList.contains('hide');
  const isModalOpen = overlay.classList.contains('open');

  if (isFormOpen) {
    _formHistoryPushed = false;
    switchView('list');
    window.scrollTo(0, 0);
    if (_formFromModal && _savedModalBookId) {
      _formFromModal = false;
      _openModalVisual(_savedModalBookId);
    }
  } else if (isModalOpen) {
    _modalHistoryPushed = false;
    _closeModalVisual();
  }
})
'@
$newPopstate = @'
window.addEventListener('popstate', () => {
  const formView = document.getElementById('view-form');
  const overlay  = document.getElementById('modal-overlay');
  const isFormOpen  = !formView.classList.contains('hide');
  const isModalOpen = overlay.classList.contains('open');

  if (isFormOpen) {
    _formHistoryPushed = false;
    switchView('list');
    window.scrollTo(0, 0);
    if (_formFromModal && _savedModalBookId) {
      _formFromModal = false;
      _openModalVisual(_savedModalBookId);
    }
  } else if (isModalOpen) {
    _modalHistoryPushed = false;
    _closeModalVisual();
  }
})
'@
$text = ExactReplace $text $oldPopstate $newPopstate

# ═══════════════════════════════════════════════════════
# TASK 2 — Remove filter-bar HTML + filter-sheet HTML
# ═══════════════════════════════════════════════════════

# Remove filter-bar (contains filter button + sort select) — from opening div to closing div
$text = RemoveBlock $text '    <div class="filter-bar"' '    <div class="result-count"'

# Remove filter-sheet HTML block (from comment to tag-sheet comment)
$text = RemoveBlock $text "`n<!-- FILTER BOTTOM SHEET -->" "`n<!-- TAG BOTTOM SHEET -->"

# ═══════════════════════════════════════════════════════
# TASK 4 — Add standalone sort bar below search-wrap
# ═══════════════════════════════════════════════════════
$oldSearchClose = @'
    <div class="search-wrap">
      <span class="search-icon"><span class="material-icons-outlined">search</span></span>
      <input class="search-inp" id="search-inp" placeholder="搜尋書名、作者、攻受描述…" autocomplete="off"/>
    </div>
    <div class="result-count"
'@
$newSearchClose = @'
    <div class="search-wrap">
      <span class="search-icon"><span class="material-icons-outlined">search</span></span>
      <input class="search-inp" id="search-inp" placeholder="搜尋書名、作者、攻受描述…" autocomplete="off"/>
    </div>
    <div class="sort-bar">
      <select class="sort-sel" id="sort-sel">
        <option value="new-desc">新增：新→舊</option>
        <option value="new-asc">新增：舊→新</option>
        <option value="stars-desc">星數：高→低</option>
        <option value="stars-asc">星數：低→高</option>
      </select>
    </div>
    <div class="result-count"
'@
$text = ExactReplace $text $oldSearchClose $newSearchClose

# Add .sort-bar CSS next to .sort-sel
$text = $text.Replace(
    ".sort-sel{",
    ".sort-bar{margin-bottom:10px}`n.sort-sel{")

# ═══════════════════════════════════════════════════════
# TASK 3 — chipHTML: rename data-tag-filter -> data-tag-click
# ═══════════════════════════════════════════════════════
$text = $text.Replace(
    'const tfAttr = clickable ? ` data-tag-filter="${esc(tag)}"` : ' + "''",
    'const tfAttr = clickable ? ` data-tag-click="${esc(tag)}"` : ' + "''")

# Also rename in renderBookCardHTML (card chips still use data-tag-filter via chipHTML)
# chipHTML now outputs data-tag-click, so no further change needed for cards

# ═══════════════════════════════════════════════════════
# TASK 3 — renderDetailHTML: only genre/relation/angst chips get data-tag-click
# ═══════════════════════════════════════════════════════
$oldTagPanel = '            ${g.has.map(t=>chipHTML(t,' + "'sm'" + ',false,true)).join(' + "''" + ')}'
$newTagPanel = "            " + '${g.has.map(t=>chipHTML(t,' + "'sm',false,['genre','relation','angst'].includes(g.key))).join('')}"
$idx = $text.IndexOf($oldTagPanel)
if ($idx -ge 0) {
    $text = $text.Remove($idx, $oldTagPanel.Length).Insert($idx, $newTagPanel)
} else { Write-Warning "Tag panel chip line not found" }

# ═══════════════════════════════════════════════════════
# TASK 3 — openModal: bind chip clicks after rendering
# ═══════════════════════════════════════════════════════
$oldOpenModal = @'
function openModal(id) {
  const b = books.find(x=>x.id===id);
  if (!b) return;
  currentModalBookId = id;
  document.getElementById('modal-content').innerHTML = renderDetailHTML(b);
  document.getElementById('modal-box').style.transform = '';
  document.getElementById('modal-overlay').classList.add('open');
'@
$newOpenModal = @'
function openModal(id) {
  const b = books.find(x=>x.id===id);
  if (!b) return;
  currentModalBookId = id;
  document.getElementById('modal-content').innerHTML = renderDetailHTML(b);
  document.querySelectorAll('#modal-content [data-tag-click]').forEach(chip => {
    chip.addEventListener('click', e => {
      e.stopPropagation();
      const tag = chip.dataset.tagClick;
      closeModal();
      searchQ = tag;
      document.getElementById('search-inp').value = tag;
      currentPage = 1;
      renderGrid();
    });
  });
  document.getElementById('modal-box').style.transform = '';
  document.getElementById('modal-overlay').classList.add('open');
'@
$text = ExactReplace $text $oldOpenModal $newOpenModal

# ═══════════════════════════════════════════════════════
# Write result
# ═══════════════════════════════════════════════════════
[System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
Write-Host "Done. File size: $((Get-Item $path).Length) bytes"
