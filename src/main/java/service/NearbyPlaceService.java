package service;

import java.util.List;

import org.apache.ibatis.session.SqlSession;

import domain.Place;
import mapper.NearbyPlaceMapper;
import util.MybatisUtil;

public class NearbyPlaceService {

	public List<Place> getNearPlaces(String stationName) {
		System.out.println("NearbyPlaceService stationName = " + stationName);

		try(SqlSession session = MybatisUtil.getSqlSession()) {
			NearbyPlaceMapper mapper = session.getMapper(NearbyPlaceMapper.class);
			List<Place> list = mapper.selectNearbyPlaces(stationName);
			System.out.println("조회된 place 개수 = " + (list == null ? "null" : list.size()));
			return list;
		}
	}
}
