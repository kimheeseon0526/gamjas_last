package service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.ibatis.session.SqlSession;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import domain.Station;
import lombok.extern.slf4j.Slf4j;
import mapper.StationMapper;
import util.APIUtil;
import util.MybatisUtil;

@Slf4j
public class StationService {

	int pageSize = 100;
	int startPage = 1;

	private static final Map<String, String> lineColorMap = new HashMap<>();

	// 호선 증가시에 key, value 값만 넣어주면 됨
	static {
		lineColorMap.put("1호선", "#0052A4");
		lineColorMap.put("2호선", "#009D3E");
		lineColorMap.put("3호선", "#EF7C1C");
		lineColorMap.put("4호선", "#00A5DE");
		lineColorMap.put("5호선", "#996CAC");
		lineColorMap.put("6호선", "#CD7C2F");
		lineColorMap.put("7호선", "#747F00");
		lineColorMap.put("8호선", "#E6186C");
		lineColorMap.put("9호선", "#BDB092");
	}

	public List<Station> getList() throws IOException {
		List<Station> list = new ArrayList<>();

		while (true) {
			int endPage = pageSize + startPage - 1;
			String page = startPage + "/" + endPage;

			String urlStr = new APIUtil().getOpenAPIURL(Station.class, "/json/subwayStationMaster/", page);
			URL url = new URL(urlStr);

			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setRequestMethod("GET");

			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));

			StringBuilder sb = new StringBuilder();
			String line;

			while ((line = rd.readLine()) != null) {
				sb.append(line);
			}

			rd.close();
			conn.disconnect();

			log.info(sb.toString());

			JsonObject jobj = JsonParser.parseString(sb.toString()).getAsJsonObject();
			JsonArray rows = jobj.getAsJsonObject("subwayStationMaster").getAsJsonArray("row");

			Gson gson = new GsonBuilder().create();
			Station[] arr = gson.fromJson(rows, Station[].class);

			log.info("arrlength :: {}", arr.length);
			log.info("gson 객체를 배열로 담은 것");

			list.addAll(Arrays.asList(arr));
			log.info("배열을 list로 담은 것");

			startPage += pageSize;
			if (pageSize > arr.length) {
				break;
			}
		}

		return list;
	}

	public void register(Station station) {
		try (SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);
			mapper.insert(station);
			session.commit();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	// =======================================================================================

	// 단선
	public List<Station> getLineStations(String lineName) {

		try (SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);

			List<Station> list = mapper.selectByLine(lineName);

			if (list == null) {
				return new ArrayList<>();
			}

			// 호선 컬러
			String lineColor = lineColorMap.getOrDefault(lineName, "#000000");
			for (Station station : list) {
				station.setLineColor(lineColor);
			}
			return list;

		} catch (Exception e) {
			e.printStackTrace();
			return new ArrayList<>();
		}
	}

	// =======================================================================================
	// 1호선 기존 방식 히스토리 보존
	/*
	public static List<List<Station>> getLine1Group() {
		try(SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);

			List<Station> mainList = mapper.selectLine1Main();
			List<Station> branchList1 = mapper.selectLine1Branch1();

			// db상에 main , branch1 -> BranchGroup 컬럼 추가
			mainList.forEach(s -> s.setLineColor(lineColorMap.get("1호선")));
			branchList1.forEach(s -> s.setLineColor(lineColorMap.get("1호선")));

			List<List<Station>> result = new ArrayList<>();
			if (!mainList.isEmpty()) result.add(mainList);
			if (!branchList1.isEmpty()) result.add(branchList1);

			return result;
		}
	}
	*/

	// 1호선: 전체 계열 조회 후 Service에서 세그먼트 분리
	public static List<List<Station>> getLine1Group() {
		log.info("===== getLine1Group 진입 =====");
		try (SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);
			List<Station> stations = mapper.selectLine1All();

			// 각 노선별로 담을 버킷
			List<Station> gyeongIn  = new ArrayList<>(); // 경인선: 인천~구일
			List<Station> gyeongBuMain = new ArrayList<>(); // 경부선 main: 구로~천안방향
			List<Station> line1Main = new ArrayList<>();  // 1호선: 서울역~청량리
			List<Station> gyeongWon = new ArrayList<>();  // 경원선: 청량리~연천

			List<Station> branchList1 = new ArrayList<>(); // 구로~광명
			List<Station> branchList2 = new ArrayList<>(); // 구로~신창 (경부선 남부)
			List<Station> branchList3 = new ArrayList<>(); // 병점~서동탄

			for (Station s : stations) {
				s.setLineColor(lineColorMap.get("1호선"));
				if (s.getOdr() == null) continue;

				String lineName = s.getLineName();
				String branch   = s.getBranchGroup();
				String name     = s.getName();
				int odr         = s.getOdr();

				switch (lineName) {
					case "경인선":
						if ("branch1".equals(branch)) gyeongIn.add(s);
						break;

					case "경부선":
						if ("main".equals(branch)) {
							if (odr >= 30) gyeongBuMain.add(s); // 신도림~서울역
							else           branchList2.add(s);  // 구로~천안
						} else if ("branch1".equals(branch)) {
							if ("광명".equals(name))   branchList1.add(s);
							if ("서동탄".equals(name)) branchList3.add(s);
						}
						break;

					case "1호선":
						if ("main".equals(branch)) line1Main.add(s);
						break;

					case "경원선":
						if ("main".equals(branch) && odr <= 65) gyeongWon.add(s); // 연천까지만
						break;
				}
			}

			// 각 구간 odr 정렬
			gyeongIn.sort((a, b)      -> Integer.compare(a.getOdr(), b.getOdr()));
			gyeongBuMain.sort((a, b)  -> Integer.compare(a.getOdr(), b.getOdr()));
			line1Main.sort((a, b)     -> Integer.compare(a.getOdr(), b.getOdr()));
			gyeongWon.sort((a, b)     -> Integer.compare(a.getOdr(), b.getOdr()));
			branchList2.sort((a, b)   -> Integer.compare(a.getOdr(), b.getOdr()));

			// mainList = 경인선 → 경부선(구로~서울역) → 1호선 → 경원선 순으로 이어붙임
			List<Station> mainList = new ArrayList<>();
			mainList.addAll(gyeongIn);
			mainList.addAll(gyeongBuMain);
			mainList.addAll(line1Main);
			mainList.addAll(gyeongWon);

			// 분기 연결점 찾기
			Station guro = mainList.stream()
							.filter(s -> "구로".equals(s.getName()))
							.findFirst().orElse(null);

			Station byeongjeom = mainList.stream()
							.filter(s -> "병점".equals(s.getName()))
							.findFirst().orElse(null);

			if (guro != null && !branchList1.isEmpty()) branchList1.add(0, guro);
			if (guro != null && !branchList2.isEmpty()) branchList2.add(0, guro);
			if (byeongjeom != null && !branchList3.isEmpty()) branchList3.add(0, byeongjeom);

			List<List<Station>> result = new ArrayList<>();
			if (!mainList.isEmpty())   result.add(mainList);
			if (!branchList1.isEmpty()) result.add(branchList1);
			if (!branchList2.isEmpty()) result.add(branchList2);
			if (!branchList3.isEmpty()) result.add(branchList3);

			return result;

		} catch (Exception e) {
			e.printStackTrace();
			return new ArrayList<>();
		}
	}

	public List<List<Station>> getLine2Group() {
		try (SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);
			List<Station> stations = mapper.selectLine2();

			List<Station> mainList = new ArrayList<>();
			List<Station> branchList1 = new ArrayList<>(); // 신도림 ~ 신정네거리
			List<Station> branchList2 = new ArrayList<>(); // 성수 ~ 용두 ~ 신설동

			for (Station s : stations) {
				s.setLineColor(lineColorMap.get("2호선"));
				String group = s.getBranchGroup();

				if ("main".equals(group)) {
					mainList.add(s);
				} else if ("branch1".equals(group)) {
					branchList1.add(s);
				} else if ("branch2".equals(group) || "branch".equals(group)) {
					branchList2.add(s);
				}
			}

			mainList.sort((a, b) -> Integer.compare(a.getOdr(), b.getOdr()));
			branchList1.sort((a, b) -> Integer.compare(a.getOdr(), b.getOdr()));
			branchList2.sort((a, b) -> Integer.compare(a.getOdr(), b.getOdr()));

			Station sindorim = mainList.stream()
							.filter(s -> "신도림".equals(s.getName()))
							.findFirst()
							.orElse(null);

			Station seongsu = mainList.stream()
							.filter(s -> "성수".equals(s.getName()))
							.findFirst()
							.orElse(null);

			if (sindorim != null && !branchList1.isEmpty()) {
				branchList1.add(0, sindorim);
			}

			if (seongsu != null && !branchList2.isEmpty()) {
				branchList2.add(0, seongsu);
			}

			log.info("2호선 mainList size = {}", mainList.size());
			log.info("2호선 branchList1 size = {}", branchList1.size());
			log.info("2호선 branchList2 size = {}", branchList2.size());

			List<List<Station>> result = new ArrayList<>();
			if (!mainList.isEmpty()) result.add(mainList);
			if (!branchList1.isEmpty()) result.add(branchList1);
			if (!branchList2.isEmpty()) result.add(branchList2);

			return result;

		} catch (Exception e) {
			e.printStackTrace();
			return new ArrayList<>();
		}
	}

	public List<List<Station>> getLine5Group() {
		try (SqlSession session = MybatisUtil.getSqlSession()) {
			StationMapper mapper = session.getMapper(StationMapper.class);
			List<Station> stations = mapper.selectLine5();

			List<Station> mainList = new ArrayList<>();
			List<Station> branchList1 = new ArrayList<>();

			for (Station s : stations) {
				s.setLineColor(lineColorMap.get("5호선"));

				if ("main".equals(s.getBranchGroup())) {
					mainList.add(s);
				} else if ("branch1".equals(s.getBranchGroup())) {
					branchList1.add(s);
				}
			}

			// 강동역을 마천 분기 시작점으로 추가
			Station gangdong = mainList.stream()
							.filter(s -> "강동".equals(s.getName()))
							.findFirst()
							.orElse(null);

			if (gangdong != null && !branchList1.isEmpty()) {
				branchList1.add(0, gangdong);
			}

			List<List<Station>> result = new ArrayList<>();
			if (!mainList.isEmpty()) result.add(mainList);
			if (!branchList1.isEmpty()) result.add(branchList1);

			return result;

		} catch (Exception e) {
			e.printStackTrace();
			return new ArrayList<>();
		}
	}
}