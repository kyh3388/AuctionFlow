package auctionFlow.controller;

import java.io.PrintWriter;
import java.time.YearMonth;

import auctionFlow.service.MainService;
import coreframe.annotations.beans.Inject;
import coreframe.annotations.http.Controller;
import coreframe.annotations.http.UrlMapping;
import coreframe.data.DataSet;
import coreframe.http.RequestData;
import coreframe.http.ViewMeta;
import jakarta.servlet.http.HttpServletResponse;

@Controller(urlPattern = "/api/auctionFlow")
public class MainController {

	@Inject
	private MainService mainService;

	
	//1. 메인 화면
	@UrlMapping("/main")
	public void main(RequestData data, ViewMeta view) {

		try {
			YearMonth currentYearMonth = YearMonth.now();
			int calendarYear = currentYearMonth.getYear();
			int calendarMonth = currentYearMonth.getMonthValue();

			//현재가 TOP 3
			DataSet topPriceList = mainService.mainTopPriceList();

			//오늘 등록된 경매
			DataSet todayAuctionList = mainService.mainTodayList();

			//현재 월 종료 예정 경매
			DataSet calendarAuctionList = mainService.mainCalendarList(calendarYear, calendarMonth);

			view.setAttribute("TOP_PRICE_LIST", topPriceList);
			view.setAttribute("TODAY_AUCTION_LIST", todayAuctionList);
			view.setAttribute("CALENDAR_AUCTION_LIST", calendarAuctionList);
			view.setAttribute("CALENDAR_YEAR", String.valueOf(calendarYear));
			view.setAttribute("CALENDAR_MONTH", String.valueOf(calendarMonth));

			//로그인·경매 등록 성공 알림
			setMainAlert(data, view);

			view.setTemplatePage("view/main");
		} catch (Exception e) {
			throw new RuntimeException("메인 화면 정보를 조회하는 중 오류가 발생했습니다.", e);
		}
	}

	
	//2. 메인 캘린더 월별 조회
	@UrlMapping("/main/calendar")
	public void mainCalendar(RequestData data, ViewMeta view) {

		try {
			DataSet params = data.getParameters();
			Integer calendarYear = parseInteger(params.getText("YEAR"));
			Integer calendarMonth = parseInteger(params.getText("MONTH"));

			//연월 검증
			if (calendarYear == null || calendarYear < 1900 || calendarYear > 2100 || calendarMonth == null || calendarMonth < 1 || calendarMonth > 12) {
				writeJsonResponse(view, HttpServletResponse.SC_BAD_REQUEST, createErrorJson("조회 연월이 올바르지 않습니다."));
				return;
			}

			DataSet calendarAuctionList = mainService.mainCalendarList(calendarYear, calendarMonth);

			String responseJson = createCalendarJson(calendarYear, calendarMonth, calendarAuctionList);

			writeJsonResponse(view, HttpServletResponse.SC_OK, responseJson);
		} catch (Exception e) {
			try {
				writeJsonResponse(view, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, createErrorJson("캘린더 정보를 불러오지 못했습니다."));
			} catch (Exception responseException) {
				throw new RuntimeException("메인 캘린더 오류 응답 처리 중 문제가 발생했습니다.", responseException);
			}
		}
	}

	
	//3. 로그인·경매 등록 성공 알림 처리
	private void setMainAlert(RequestData data, ViewMeta view) {

		Object loginSuccessAlert = data.getSession().getAttribute("LOGIN_SUCCESS_ALERT");
		if ("Y".equals(loginSuccessAlert)) {
			view.setAttribute("LOGIN_SUCCESS_ALERT", "Y");
			data.getSession().removeAttribute("LOGIN_SUCCESS_ALERT");
		}

		Object auctionRegisterSuccessAlert = data.getSession().getAttribute("AUCTION_REGISTER_SUCCESS_ALERT");
		if ("Y".equals(auctionRegisterSuccessAlert)) {
			view.setAttribute("AUCTION_REGISTER_SUCCESS_ALERT", "Y");
			data.getSession().removeAttribute("AUCTION_REGISTER_SUCCESS_ALERT");
		}
	}


	//4. 문자열을 정수로 변환
	private Integer parseInteger(String value) {
		if (value == null || value.isBlank()) return null;
		
		try {
			return Integer.valueOf(value.trim());
		} catch (NumberFormatException e) {
			return null;
		}
	}


	//5. 캘린더 조회 성공 JSON 생성
	private String createCalendarJson(int calendarYear, int calendarMonth, DataSet calendarAuctionList) {

		int auctionCount = 0;
		if (calendarAuctionList != null) {
			auctionCount = calendarAuctionList.getCount("A_NO");
		}

		StringBuilder json = new StringBuilder();
		json.append("{");
		json.append("\"success\":true");
		json.append(",\"year\":");
		json.append(calendarYear);
		json.append(",\"month\":");
		json.append(calendarMonth);
		json.append(",\"auctions\":[");

		for (int rowIndex = 0; rowIndex < auctionCount; rowIndex++) {

			if (rowIndex > 0) {
				json.append(",");
			}

			long auctionNo = calendarAuctionList.getLong("A_NO", rowIndex);
			String auctionTitle = calendarAuctionList.getText("A_TITLE", rowIndex);
			long currentPrice = calendarAuctionList.getLong("A_CURRENT_PRICE", rowIndex);
			long bidCount = calendarAuctionList.getLong("A_BID_COUNT", rowIndex);
			String endDate = calendarAuctionList.getText("A_END_DATE", rowIndex);
			String endDatetime = calendarAuctionList.getText("A_END_DATETIME", rowIndex);
			String imageStoredName = calendarAuctionList.getText("IMG_STORED_NAME", rowIndex);

			json.append("{");
			json.append("\"auctionNo\":");
			json.append(auctionNo);
			json.append(",\"auctionTitle\":\"");
			json.append(escapeJson(auctionTitle));
			json.append("\"");
			json.append(",\"currentPrice\":");
			json.append(currentPrice);
			json.append(",\"bidCount\":");
			json.append(bidCount);
			json.append(",\"endDate\":\"");
			json.append(escapeJson(endDate));
			json.append("\"");
			json.append(",\"endDatetime\":\"");
			json.append(escapeJson(endDatetime));
			json.append("\"");
			json.append(",\"imageStoredName\":\"");
			json.append(escapeJson(imageStoredName));
			json.append("\"");
			json.append("}");
		}
		json.append("]");
		json.append("}");
		return json.toString();
	}

	
	//6. 오류 JSON 생성
	private String createErrorJson(String message) {
		return "{" + "\"success\":false," + "\"message\":\"" + escapeJson(message) + "\"" + "}";
	}

	
	//7. JSON 특수문자 처리
	private String escapeJson(String value) {
		if (value == null) return "";
		return value.replace("\\", "\\\\")
			.replace("\"", "\\\"")
			.replace("\r", "\\r")
			.replace("\n", "\\n")
			.replace("\t", "\\t")
			.replace("\b", "\\b")
			.replace("\f", "\\f");
	}


	//8. JSON 직접 응답
	private void writeJsonResponse(ViewMeta view, int statusCode, String json) throws Exception {
		view.disable();
		HttpServletResponse response = view.getHttpServletResponse();
		response.resetBuffer();
		response.setStatus(statusCode);
		response.setCharacterEncoding("UTF-8");
		response.setContentType("application/json; charset=UTF-8");
		PrintWriter writer = response.getWriter();
		writer.print(json);
		writer.flush();
		response.flushBuffer();
	}
}