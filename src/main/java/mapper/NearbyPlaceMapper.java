package mapper;

import java.util.List;

import domain.Place;
import org.apache.ibatis.annotations.Param;

public interface NearbyPlaceMapper {
	List<Place> selectNearbyPlaces(@Param("stationName") String stationName);
}

