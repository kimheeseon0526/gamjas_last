package domain;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Place {
	private String stationId;	//고유 역 id
	private String stationName;	//역이름
	private String title;	//제목
	private Double lat;
	private Double lng;
	private String type;	//카데고리
	private String addr;	//주소
	private Double dist;	//거리

}
