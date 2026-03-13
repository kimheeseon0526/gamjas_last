<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<c:set var="cp" value="${pageContext.request.contextPath}" />

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>GAMJAS - 지하철 노선도</title>

  <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=6cc3b513c1123ed7909f8f5cf20cc721"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

  <%@ include file="../common/nav.jsp" %>

  <style>
      html, body { margin: 0; padding: 0; min-height: 100vh; }

      .filter-tabs {
          display: flex;
          gap: 8px;
          margin-bottom: 12px;
          flex-wrap: wrap;
      }
      .filter-tab {
          padding: 5px 14px;
          border-radius: 20px;
          border: 1.5px solid #ddd;
          background: white;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.15s;
          color: #555;
      }
      .filter-tab:hover { border-color: #aaa; }
      .filter-tab.active { color: white; border-color: transparent; }
      .filter-tab[data-type="all"].active        { background: #444; }
      .filter-tab[data-type="restaurant"].active { background: #e74c3c; }
      .filter-tab[data-type="attraction"].active  { background: #1a9e8f; }
      .filter-tab[data-type="festival"].active    { background: #e67e22; }

      .recomm-card {
          background: white;
          border-radius: 8px;
          padding: 12px 14px;
          box-shadow: 0 1px 4px rgba(0,0,0,0.08);
          cursor: pointer;
          transition: box-shadow 0.2s, transform 0.15s;
      }
      .recomm-card:hover {
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          transform: translateY(-2px);
      }
      .recomm-card.hidden { display: none; }
      .place-title {
          font-size: 14px;
          font-weight: 700;
          color: #222;
          margin: 0 0 6px;
      }
      .place-meta {
          display: flex;
          align-items: center;
          gap: 6px;
          margin-bottom: 4px;
      }
      .place-dist { font-size: 13px; font-weight: 600; color: #333; }
      .place-badge {
          font-size: 11px;
          font-weight: 600;
          padding: 2px 8px;
          border-radius: 20px;
          color: white;
      }
      .badge-restaurant { background: #e74c3c; }
      .badge-attraction  { background: #1a9e8f; }
      .badge-festival    { background: #e67e22; }
      .place-addr {
          font-size: 11px;
          color: #999;
          margin: 0;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
      }
  </style>
</head>

<body>
<div class="line-selectors">
  <div class="line-wrap" style="display: flex; gap: 12px; flex-wrap: wrap;">
    <div class="line-item"><button style="background-color: #0052A4;" value="1호선">1</button><span>1호선</span></div>
    <div class="line-item"><button style="background-color: #00A84D;" value="2호선">2</button><span>2호선</span></div>
    <div class="line-item"><button style="background-color: #EF7C1C;" value="3호선">3</button><span>3호선</span></div>
    <div class="line-item"><button style="background-color: #00A4E3;" value="4호선">4</button><span>4호선</span></div>
    <div class="line-item"><button style="background-color: #996CAC;" value="5호선">5</button><span>5호선</span></div>
    <div class="line-item"><button style="background-color: #CD7C2F;" value="6호선">6</button><span>6호선</span></div>
    <div class="line-item"><button style="background-color: #747F00;" value="7호선">7</button><span>7호선</span></div>
    <div class="line-item"><button style="background-color: #E6186C;" value="8호선">8</button><span>8호선</span></div>
    <div class="line-item"><button style="background-color: #BDB092;" value="9호선">9</button><span>9호선</span></div>
  </div>
</div>

<div id="map-wrapper" style="display:flex; justify-content:space-between; align-items:flex-start; gap:24px; margin-top:32px; margin-bottom:64px; padding:0 5%;">
  <div id="map" style="flex:1; min-width:600px; height:600px; border-radius:10px; box-shadow:0 2px 8px rgba(0,0,0,0.1);"></div>

  <div id="mission-box" style="
    flex: 0.8;
    min-width: 280px;
    height: 600px;
    background: #f8f8f8;
    border-radius: 10px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
    padding: 20px;
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
  ">
    <h3 style="margin: 0 0 6px;">추천 리스트</h3>
    <p id="recomm-header" style="font-size:13px; color:#666; margin:0 0 10px;"></p>
    <div id="filter-tab-area"></div>
    <div id="recomm-grid" style="flex:1; overflow-y:auto; min-height:0; display:grid; grid-template-columns:1fr 1fr; gap:10px; padding-bottom:10px;">
      <div id="recomm-placeholder" style="grid-column:1/-1;">
        <p style="color:#aaa; font-size:13px;">마커를 클릭하면 정보가 표시됩니다.</p>
      </div>
    </div>
  </div>
</div>

<script>
  let openInfoWindow = null;
  const map = new kakao.maps.Map(document.getElementById("map"), {
    center: new kakao.maps.LatLng(37.5665, 126.9780),
    level: 6
  });

  let markers = [];
  let polylines = [];
  let placeOverlays = [];
  let currentFilter = "all";

  function clearMap() {
    markers.forEach(m => m.setMap(null)); markers = [];
    polylines.forEach(p => p.setMap(null)); polylines = [];
    placeOverlays.forEach(o => o.setMap(null)); placeOverlays = [];
    if (openInfoWindow) { openInfoWindow.close(); openInfoWindow = null; }

    document.getElementById("recomm-header").textContent = "";
    document.getElementById("filter-tab-area").innerHTML = "";
    const grid = document.getElementById("recomm-grid");
    grid.innerHTML = '<div id="recomm-placeholder" style="grid-column:1/-1;"><p style="color:#aaa;font-size:13px;">마커를 클릭하면 정보가 표시됩니다.</p></div>';
    currentFilter = "all";
  }

  function getFontAwesomeIcon(type) {
    if (type === "restaurant") return '<i class="fas fa-utensils" style="color:tomato;font-size:16px;"></i>';
    if (type === "festival")   return '<i class="fas fa-music" style="color:orange;font-size:16px;"></i>';
    if (type === "attraction") return '<i class="fas fa-camera" style="color:teal;font-size:16px;"></i>';
    return '<i class="fas fa-map-marker-alt" style="color:gray;font-size:16px;"></i>';
  }

  function getTypeBadge(type) {
    if (type === "restaurant") return '<span class="place-badge badge-restaurant">식당</span>';
    if (type === "festival")   return '<span class="place-badge badge-festival">축제</span>';
    if (type === "attraction") return '<span class="place-badge badge-attraction">관광</span>';
    return '<span class="place-badge" style="background:#999">기타</span>';
  }

  function applyFilter(type) {
    currentFilter = type;
    document.querySelectorAll(".filter-tab").forEach(tab => {
      tab.classList.toggle("active", tab.dataset.type === type);
    });
    document.querySelectorAll(".recomm-card").forEach(card => {
      card.classList.toggle("hidden", type !== "all" && card.dataset.type !== type);
    });
    const visible = document.querySelectorAll(".recomm-card:not(.hidden)").length;
    const header = document.getElementById("recomm-header");
    if (header) header.textContent = header.dataset.base + " (" + visible + "개)";
  }

  function drawPlaceMarkers(places, stationName) {
    placeOverlays.forEach(p => p.setMap(null));
    placeOverlays = [];

    const header = document.getElementById("recomm-header");
    const tabArea = document.getElementById("filter-tab-area");
    const grid = document.getElementById("recomm-grid");

    grid.innerHTML = "";

    if (!places || places.length === 0) {
      header.textContent = "";
      tabArea.innerHTML = "";
      grid.innerHTML = '<div style="grid-column:1/-1;"><p>반경 1km 내의 추천 리스트가 없습니다</p></div>';
      return;
    }

    // 헤더
    header.dataset.base = (stationName || "") + " 주변 장소";
    header.textContent = header.dataset.base + " (" + places.length + "개)";

    // 필터 탭
    tabArea.innerHTML =
      '<div class="filter-tabs">' +
      '<button class="filter-tab active" data-type="all">전체</button>' +
      '<button class="filter-tab" data-type="restaurant">식당</button>' +
      '<button class="filter-tab" data-type="attraction">관광</button>' +
      '<button class="filter-tab" data-type="festival">축제</button>' +
      '</div>';
    tabArea.querySelectorAll(".filter-tab").forEach(tab => {
      tab.addEventListener("click", () => applyFilter(tab.dataset.type));
    });

    // 카드
    places.forEach(place => {
      const lat = parseFloat(place.lat);
      const lng = parseFloat(place.lng);
      if (isNaN(lat) || isNaN(lng)) return;

      const latlng = new kakao.maps.LatLng(lat, lng);

      const overlayContent = document.createElement("div");
      overlayContent.innerHTML = getFontAwesomeIcon(place.type);
      overlayContent.style.cssText = "position:relative;transform:translate(-50%,-100%);display:inline-block;cursor:pointer;";
      const overlay = new kakao.maps.CustomOverlay({ position: latlng, content: overlayContent, yAnchor: 1, map: map });
      placeOverlays.push(overlay);
      overlayContent.addEventListener("click", () => map.panTo(latlng));

      const item = document.createElement("div");
      item.classList.add("recomm-card");
      item.dataset.type = place.type;
      item.innerHTML =
        '<p class="place-title">' + place.title + '</p>' +
        '<div class="place-meta">' +
        '<span class="place-dist">' + Number(place.dist).toFixed(0) + 'm</span>' +
        getTypeBadge(place.type) +
        '</div>' +
        '<p class="place-addr">' + place.addr + '</p>';
      item.addEventListener("click", () => map.panTo(latlng));
      grid.appendChild(item);
    });

    currentFilter = "all";
  }

  function fetchNearbyPlaces(station) {
    const stationName = station.name || station.BLDN_NM;
    $.ajax({
      url: "${cp}/nearbyPlaces?stationName=" + encodeURIComponent(stationName),
      method: "GET",
      success: function(data) { drawPlaceMarkers(data, stationName); },
      error: function() { alert("주변 장소 정보를 불러오지 못했습니다."); }
    });
  }

  function renderStations(segment) {
    if (!Array.isArray(segment) || segment.length === 0) return;
    const lineCoords = [];

    segment.forEach(station => {
      const lat = parseFloat(station.lat ?? station.LAT);
      const lng = parseFloat(station.lng ?? station.LOT);
      if (isNaN(lat) || isNaN(lng)) return;

      const latlng = new kakao.maps.LatLng(lat, lng);
      lineCoords.push(latlng);

      const markerContent = document.createElement("div");
      markerContent.style.cssText =
        "width:10px;height:10px;border-radius:50%;background:white;" +
        "border:3px solid " + (station.lineColor || "#333") + ";" +
        "cursor:pointer;transition:transform 0.15s;" +
        "position:relative;transform:translate(-50%,-50%);";

      markerContent.addEventListener("mouseenter", () => {
        markerContent.style.transform = "translate(-50%,-50%) scale(1.8)";
        markerContent.style.background = station.lineColor || "#333";
      });
      markerContent.addEventListener("mouseleave", () => {
        markerContent.style.transform = "translate(-50%,-50%) scale(1)";
        markerContent.style.background = "white";
      });

      new kakao.maps.CustomOverlay({ position: latlng, content: markerContent, map: map });

      const stationName = station.name || station.BLDN_NM || "";
      const tooltip = document.createElement("div");
      tooltip.style.cssText =
        "position:absolute;bottom:18px;left:50%;transform:translateX(-50%);" +
        "background:white;border-radius:6px;overflow:hidden;" +
        "box-shadow:0 2px 8px rgba(0,0,0,0.18);white-space:nowrap;display:none;z-index:10;";
      tooltip.innerHTML =
        '<div style="height:4px;background:' + (station.lineColor || "#333") + ';"></div>' +
        '<div style="padding:5px 10px;font-size:12px;font-weight:600;color:#222;">' + stationName + '</div>';
      markerContent.appendChild(tooltip);

      markerContent.addEventListener("click", () => {
        document.querySelectorAll(".station-tooltip").forEach(el => el.style.display = "none");
        tooltip.style.display = "block";
        tooltip.classList.add("station-tooltip");
        fetchNearbyPlaces(station);
      });

      markers.push(new kakao.maps.CustomOverlay({ position: latlng, content: markerContent, map: map }));
    });

    if (lineCoords.length === 0) return;

    const firstStation = segment[0];
    const isMainLoopLine = (firstStation.lineName || "") === "2호선" &&
      (firstStation.branchGroup || "") === "main" &&
      segment.length > 10;
    const path = [...lineCoords];
    if (isMainLoopLine) path.push(path[0]);

    polylines.push(new kakao.maps.Polyline({
      map: map, path: path,
      strokeWeight: 4,
      strokeColor: firstStation.lineColor || "#333",
      strokeOpacity: 0.9,
      strokeStyle: "solid"
    }));
  }

  function moveMapToFirstStation(data) {
    let first = Array.isArray(data) && Array.isArray(data[0]) ? data[0][0]
      : Array.isArray(data) ? data[0] : null;
    if (!first) return;
    const lat = parseFloat(first.lat ?? first.LAT);
    const lng = parseFloat(first.lng ?? first.LOT);
    if (!isNaN(lat) && !isNaN(lng)) map.setCenter(new kakao.maps.LatLng(lat, lng));
  }

  document.querySelectorAll(".line-item button").forEach(btn => {
    btn.addEventListener("click", () => {
      fetch("${cp}/lineinfo?lineName=" + encodeURIComponent(btn.value))
        .then(r => { if (!r.ok) throw new Error(); return r.json(); })
        .then(data => {
          clearMap();
          moveMapToFirstStation(data);
          if (Array.isArray(data) && Array.isArray(data[0])) {
            data.forEach(seg => renderStations(seg));
          } else {
            renderStations(data);
          }
        })
        .catch(() => alert("노선 정보를 불러오지 못했습니다."));
    });
  });
</script>
<%@ include file="../common/footer.jsp" %>
</body>
</html>