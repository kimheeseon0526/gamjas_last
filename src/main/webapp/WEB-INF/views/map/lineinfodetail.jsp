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
      #map-wrapper { min-height: 700px; }
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

<div id="map-wrapper" style="display: flex; justify-content: space-between; align-items: flex-start; gap: 24px; margin-top: 32px; margin-bottom: 64px; padding: 0 5%;">
  <div id="map" style="flex: 1; min-width: 600px; height: 600px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);"></div>
  <div id="mission-box" style="flex: 0.8; min-width: 280px; height: 600px; background: #f8f8f8; border-radius: 10px; box-shadow: 0 2px 6px rgba(0,0,0,0.08); padding: 20px;">
    <h3 style="margin-bottom: 12px;">추천 리스트</h3>
    <div id="recomm-content">마커를 클릭하면 정보가 표시됩니다.</div>
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

  function clearMap() {
    markers.forEach(m => m.setMap(null));
    markers = [];
    polylines.forEach(p => p.setMap(null));
    polylines = [];
    placeOverlays.forEach(o => o.setMap(null));
    placeOverlays = [];
    if (openInfoWindow) { openInfoWindow.close(); openInfoWindow = null; }
    const contentBox = document.getElementById("recomm-content");
    if (contentBox) contentBox.innerHTML = "마커를 클릭하면 정보가 표시됩니다.";
  }

  function getFontAwesomeIcon(type) {
    if (type === "restaurant") return '<i class="fas fa-utensils" style="color:tomato; font-size:16px;"></i>';
    if (type === "festival")   return '<i class="fas fa-music" style="color:orange; font-size:16px;"></i>';
    if (type === "attraction") return '<i class="fas fa-camera" style="color:teal; font-size:16px;"></i>';
    return '<i class="fas fa-map-marker-alt" style="color:gray; font-size:16px;"></i>';
  }

  function drawPlaceMarkers(places) {
    placeOverlays.forEach(p => p.setMap(null));
    placeOverlays = [];
    const contentBox = document.getElementById("recomm-content");
    contentBox.innerHTML = "";

    if (!places || places.length === 0) {
      contentBox.innerHTML = "<p>반경 1km 내의 추천 리스트가 없습니다</p>";
      return;
    }

    places.forEach(place => {
      const lat = parseFloat(place.lat);
      const lng = parseFloat(place.lng);
      if (isNaN(lat) || isNaN(lng)) return;

      const latlng = new kakao.maps.LatLng(lat, lng);
      const overlayContent = document.createElement("div");
      overlayContent.innerHTML = getFontAwesomeIcon(place.type);
      overlayContent.style.cssText = "position:relative; transform:translate(-50%,-100%); display:inline-block; cursor:pointer;";

      const overlay = new kakao.maps.CustomOverlay({ position: latlng, content: overlayContent, yAnchor: 1, map: map });
      placeOverlays.push(overlay);

      const item = document.createElement("div");
      item.classList.add("recomm-card");
      item.innerHTML =
        '<h4 style="margin: 6px 0 4px;">' + place.title + '</h4>' +
        '<p style="font-size: 14px; color: #444;">' + place.addr + '</p>' +
        '<p style="font-size: 13px; color: #888;">' + place.type + ' \u2022 ' + Number(place.dist).toFixed(0) + 'm 거리</p>';
      contentBox.appendChild(item);

      overlayContent.addEventListener("click", () => map.panTo(latlng));
    });
  }

  function fetchNearbyPlaces(station) {
    const stationName = station.name || station.BLDN_NM;
    $.ajax({
      url: "${cp}/nearbyPlaces?stationName=" + encodeURIComponent(stationName),
      method: "GET",
      success: function(data) {
        console.log("===== nearbyPlaces 응답 =====", data);
        console.log("타입:", typeof data, Array.isArray(data));
        drawPlaceMarkers(data); },
      error: function() {
        console.error("주변 장소 요청 실패", xhr, status, err);
        alert("주변 장소 정보 못불러옴"); }
    });
  }

  function renderStations(segment) {
    if (!Array.isArray(segment) || segment.length === 0) return;

    const lineCoords = [];

    segment.forEach(station => {
      const lat = parseFloat(station.lat ?? station.LAT);
      const lng = parseFloat(station.lng ?? station.LOT);

      if (isNaN(lat) || isNaN(lng)) {
        console.warn("좌표 이상:", station);
        return;
      }

      const latlng = new kakao.maps.LatLng(lat, lng);
      lineCoords.push(latlng);

      const markerContent = document.createElement("div");
      markerContent.style.cssText =
        "width:10px; height:10px; border-radius:50%; background:white;" +
        "border:3px solid " + (station.lineColor || "#333") + ";" +
        "cursor:pointer; transition:transform 0.15s;" +
        "position:relative; transform:translate(-50%,-50%);";

      markerContent.addEventListener("mouseenter", () => {
        markerContent.style.transform = "translate(-50%,-50%) scale(1.8)";
        markerContent.style.background = station.lineColor || "#333";
      });
      markerContent.addEventListener("mouseleave", () => {
        markerContent.style.transform = "translate(-50%,-50%) scale(1)";
        markerContent.style.background = "white";
      });

      const customOverlay = new kakao.maps.CustomOverlay({ position: latlng, content: markerContent, map: map });

      const stationName = station.name || station.BLDN_NM || "";
      const tooltip = document.createElement("div");
      tooltip.style.cssText =
        "position:absolute; bottom:18px; left:50%; transform:translateX(-50%);" +
        "background:white; border-radius:6px; overflow:hidden;" +
        "box-shadow:0 2px 8px rgba(0,0,0,0.18); white-space:nowrap; display:none; z-index:10;";
      tooltip.innerHTML =
        '<div style="height:4px; background:' + (station.lineColor || "#333") + ';"></div>' +
        '<div style="padding:5px 10px; font-size:12px; font-weight:600; color:#222;">' + stationName + '</div>';
      markerContent.appendChild(tooltip);

      markerContent.addEventListener("click", () => {
        // 다른 툴팁 닫기
        document.querySelectorAll(".station-tooltip").forEach(el => el.style.display = "none");
        tooltip.style.display = "block";
        tooltip.classList.add("station-tooltip");
        fetchNearbyPlaces(station);
      });

      markers.push(customOverlay);
    });

    if (lineCoords.length === 0) return;

    const firstStation = segment[0];
    const lineName = firstStation.lineName || firstStation.ROUTE || "";
    const branchGroup = firstStation.branchGroup || firstStation.BranchGroup || "";

    const isMainLoopLine = lineName === "2호선" && branchGroup === "main" && segment.length > 10;
    const path = [...lineCoords];
    if (isMainLoopLine) path.push(path[0]);

    const polyline = new kakao.maps.Polyline({
      map: map,
      path: path,
      strokeWeight: 4,
      strokeColor: firstStation.lineColor || "#333",
      strokeOpacity: 0.9,
      strokeStyle: "solid"
    });
    polylines.push(polyline);
  }

  function moveMapToFirstStation(data) {
    let firstStation = null;
    if (Array.isArray(data) && Array.isArray(data[0]) && data[0].length > 0) {
      firstStation = data[0][0];
    } else if (Array.isArray(data) && data.length > 0) {
      firstStation = data[0];
    }
    if (!firstStation) return;

    const lat = parseFloat(firstStation.lat ?? firstStation.LAT);
    const lng = parseFloat(firstStation.lng ?? firstStation.LOT);
    if (!isNaN(lat) && !isNaN(lng)) {
      map.setCenter(new kakao.maps.LatLng(lat, lng));
    }
  }

  document.querySelectorAll(".line-item button").forEach(btn => {
    btn.addEventListener("click", () => {
      const line = btn.value;
      fetch("${cp}/lineinfo?lineName=" + encodeURIComponent(line))
        .then(resp => {
          if (!resp.ok) throw new Error("HTTP error! status: " + resp.status);
          return resp.json();
        })
        .then(data => {
          console.log("===== 서버 응답 =====", data);
          clearMap();
          moveMapToFirstStation(data);

          if (Array.isArray(data) && Array.isArray(data[0])) {
            data.forEach((segment, index) => {
              console.log("segment[" + index + "]:", segment);
              renderStations(segment);
            });
          } else {
            renderStations(data);
          }
        })
        .catch(err => {
          console.error("노선 정보 불러오기 실패:", err);
          alert("노선 정보를 불러오지 못했습니다.");
        });
    });
  });
</script>
<%@ include file="../common/footer.jsp" %>
</body>
</html>