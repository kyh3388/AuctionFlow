package auctionFlow.service;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;

import coreframe.annotations.beans.Bean;
import coreframe.data.DataSet;
import coreframe.data.Interaction;
import coreframe.data.InteractionFactory;

@Bean
public class MainService {
	
	private static final DateTimeFormatter DB_DATETIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
	
	//메인 현재가 TOP 3 조회
	public DataSet mainTopPriceList() throws Exception {
		DataSet input = DataSet.newDefault();
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("main/topPriceList", input);
		return output;
	}

	//메인 오늘 등록 경매 조회
	public DataSet mainTodayList() throws Exception {
		DataSet input = DataSet.newDefault();
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("main/todayList", input);
		return output;
	}

	//3. 지정한 월의 종료 예정 경매 조회
		public DataSet mainCalendarList(int calendarYear, int calendarMonth) throws Exception {

			YearMonth yearMonth = YearMonth.of(calendarYear, calendarMonth);

			LocalDateTime startDatetime = yearMonth.atDay(1).atStartOfDay();
			LocalDateTime endDatetime = yearMonth.plusMonths(1).atDay(1).atStartOfDay();

			DataSet input = DataSet.newDefault();
			input.put("CALENDAR_START_DATETIME", startDatetime.format(DB_DATETIME_FORMATTER));
			input.put("CALENDAR_END_DATETIME", endDatetime.format(DB_DATETIME_FORMATTER));

			Interaction interaction = InteractionFactory.getInteraction();
			return interaction.execute("main/calendarList", input);
		}
	}
