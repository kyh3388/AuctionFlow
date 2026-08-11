package auctionFlow.controller;

import java.io.IOException;
import java.net.URLConnection;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import auctionFlow.exception.BidException;
import auctionFlow.service.AuctionService;
import auctionFlow.websocket.AuctionWebSocketManager;
import coreframe.annotations.beans.Inject;
import coreframe.annotations.beans.Property;
import coreframe.annotations.http.Controller;
import coreframe.annotations.http.UrlMapping;
import coreframe.data.DataSet;
import coreframe.http.MultipartFile;
import coreframe.http.RequestData;
import coreframe.http.ViewMeta;
import jakarta.servlet.http.HttpServletResponse;

@Controller(urlPattern = "/api/auctionFlow/auction")
public class AuctionController {

    // 경매별 동시 입찰 시연 상태를 서버 메모리에 저장한다.
    private static final long BID_DEMO_COOLDOWN_MILLIS = 5_000L;
    private static final long BID_DEMO_RUNNING_TIMEOUT_MILLIS = 10L * 60L * 1_000L;
    private static final Map<Long, BidDemoState> BID_DEMO_STATE_MAP = new HashMap<>();

    @Inject
    private AuctionService auctionService;

    @Property("auction.image.path")
    private String auctionImagePath;

    // running=true: 시연 중 / running=false: 쿨타임 중
    private static class BidDemoState {
        private String demoId;
        private boolean running;
        private long startedAt;
        private long availableAt;

        private BidDemoState(String demoId, boolean running, long startedAt, long availableAt) {
            this.demoId = demoId;
            this.running = running;
            this.startedAt = startedAt;
            this.availableAt = availableAt;
        }
    }

    // ============================================================
    // 1. 경매 등록
    // ============================================================

    @UrlMapping("/registerForm")
    public void auctionRegisterForm(RequestData data, ViewMeta view) {
        if (getLoginMemberNo(data) == null) {
            view.setRedirectUrl("../member/loginForm");
            return;
        }

        view.setAttribute("A_DURATION_TIME", "10080");
        view.setTemplatePage("view/auction/register");
    }

    @UrlMapping("/register")
    public void auctionRegister(RequestData data, ViewMeta view) {
        try {
            // 1. 로그인 확인
            Long loginMemberNo = getLoginMemberNo(data);

            if (loginMemberNo == null) {
                view.setRedirectUrl("../member/loginForm");
                return;
            }

            // 2. 입력값 조회
            DataSet params = data.getParameters();

            String category = params.getText("A_CATEGORY");
            String title = params.getText("A_TITLE");
            String content = params.getText("A_CONTENT");
            String startPriceText = params.getText("A_START_PRICE");
            String durationText = params.getText("A_DURATION_TIME");

            // 입력 오류가 나면 사용자가 입력했던 값은 다시 화면에 보여준다.
            view.setAttribute("A_CATEGORY", category == null ? "" : category);
            view.setAttribute("A_TITLE", title == null ? "" : title);
            view.setAttribute("A_CONTENT", content == null ? "" : content);
            view.setAttribute("A_START_PRICE", startPriceText == null ? "" : startPriceText);
            view.setAttribute("A_DURATION_TIME", durationText == null ? "" : durationText);

            if (category == null
                || category.isBlank()
                || title == null
                || title.isBlank()
                || content == null
                || content.isBlank()
                || startPriceText == null
                || startPriceText.isBlank()
                || durationText == null
                || durationText.isBlank()) {

                view.setAttribute("AUCTION_REGISTER_MESSAGE", "상품 등록 정보를 모두 입력해 주세요.");
                view.setTemplatePage("view/auction/register");
                return;
            }

            category = category.trim();
            title = title.trim();
            content = content.trim();
            startPriceText = startPriceText.trim();
            durationText = durationText.trim();

            // 3. 카테고리 검증
            boolean validCategory = "고서적".equals(category) || "미술품".equals(category) || "골동품".equals(category) || "기타".equals(category);

            if (!validCategory) {
                view.setAttribute("AUCTION_REGISTER_MESSAGE", "카테고리를 다시 선택해 주세요.");
                view.setTemplatePage("view/auction/register");
                return;
            }

            // 4. 시작가 검증
            Long startPrice = parsePositiveLong(startPriceText);
            if (startPrice == null || startPrice < 50_000L) {
                view.setAttribute("AUCTION_REGISTER_MESSAGE", "시작가는 최소 50,000원부터 등록할 수 있습니다.");
                view.setTemplatePage("view/auction/register");
                return;
            }

            // 5. 경매 진행시간 검증
            Long durationMinutes = parsePositiveLong(durationText);
            boolean validDuration =
                durationMinutes != null && (durationMinutes == 1L || durationMinutes == 5L
					                    || durationMinutes == 10L || durationMinutes == 30L
					                    || durationMinutes == 60L || durationMinutes == 180L
					                    || durationMinutes == 360L || durationMinutes == 720L
					                    || durationMinutes == 1_440L || durationMinutes == 4_320L
					                    || durationMinutes == 10_080L || durationMinutes == 20_160L
					                    || durationMinutes == 43_200L);

            if (!validDuration) {
                view.setAttribute("AUCTION_REGISTER_MESSAGE", "경매 진행시간을 다시 선택해 주세요.");
                view.setTemplatePage("view/auction/register");
                return;
            }

            // 6. 이미지 검증
            MultipartFile mainImage = data.getFile("MAIN_IMAGE");

            if (mainImage == null || mainImage.isEmpty()) {
                view.setAttribute("AUCTION_REGISTER_MESSAGE", "대표 이미지를 등록해 주세요.");
                view.setTemplatePage("view/auction/register");
                return;
            }

            List<MultipartFile> subImages = new ArrayList<>();
            List<MultipartFile> uploadedSubImages = data.getFiles("SUB_IMAGES");

            if (uploadedSubImages != null) {
                for (MultipartFile file : uploadedSubImages) {
                    if (file != null && !file.isEmpty()) {
                        subImages.add(file);
                    }
                }
            }

            // 7. 종료시간 계산 후 등록 
            String endDatetime = LocalDateTime.now()
                .plusMinutes(durationMinutes)
                .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

            auctionService.auctionRegister(loginMemberNo, category, title, content, startPrice, endDatetime, mainImage, subImages);

            data.getSession().setAttribute("AUCTION_REGISTER_SUCCESS_ALERT", "Y");
            view.setRedirectUrl("../main");

        } catch (Exception e) {
            throw new RuntimeException("상품 등록 처리 중 오류가 발생했습니다.", e);
        }
    }

    // ============================================================
    // 2. 경매 목록 / 검색
    // ============================================================

    @UrlMapping("/pastList")
    public void pastList(RequestData data, ViewMeta view) {
        try {
            String sort = normalizeSort(data.getParameters().getText("SORT"));

            DataSet auctionPastList = auctionService.auctionSelectPastList(sort);

            view.setAttribute("AUCTION_PAST_LIST", auctionPastList);
            view.setAttribute("SELECTED_SORT", sort);
            view.setTemplatePage("view/auction/pastList");

        } catch (Exception e) {
            throw new RuntimeException("지난 경매 목록 조회 중 오류가 발생했습니다.", e);
        }
    }

    @UrlMapping("/search")
    public void auctionSearch(RequestData data, ViewMeta view) {
        try {
            DataSet params = data.getParameters();

            String keyword = params.getText("KEYWORD");
            keyword = keyword == null ? "" : keyword.trim();

            String sort = normalizeSort(params.getText("SORT"));

            DataSet auctionList = auctionService.auctionSearchList(keyword, sort);

            view.setAttribute("AUCTION_LIST", auctionList);
            view.setAttribute("SEARCH_KEYWORD", keyword);
            view.setAttribute("SELECTED_SORT", sort);
            view.setTemplatePage("view/auction/searchList");

        } catch (Exception e) {
            throw new RuntimeException("경매 상품 검색 중 오류가 발생했습니다.", e);
        }
    }

    @UrlMapping("/ongoing")
    public void ongoing(RequestData data, ViewMeta view) {
        try {
            String sort = normalizeSort(data.getParameters().getText("SORT"));

            DataSet auctionList = auctionService.auctionSelectList(sort);

            view.setAttribute("AUCTION_LIST", auctionList);
            view.setAttribute("SELECTED_SORT", sort);
            view.setTemplatePage("view/auction/ongoing");

        } catch (Exception e) {
            throw new RuntimeException("진행 중 경매 목록 조회 중 오류가 발생했습니다.", e);
        }
    }

    // ============================================================
    // 3. 경매 상세
    // ============================================================

    @UrlMapping("/detail")
    public void auctionDetail(RequestData data, ViewMeta view) {
        try {
            Long auctionNo = parsePositiveLong(data.getParameters().getText("A_NO"));

            if (auctionNo == null) {
                view.setRedirectUrl("../main");
                return;
            }

            DataSet detailOutput = auctionService.auctionSelectDetail(auctionNo);

            if (detailOutput == null || detailOutput.getCount("A_NO") == 0) {
                view.setRedirectUrl("../main");
                return;
            }

            DataSet bidListOutput = auctionService.auctionSelectBidList(auctionNo);

            view.setAttribute("AUCTION_DETAIL", detailOutput);
            view.setAttribute("AUCTION_IMAGE_LIST", detailOutput);
            view.setAttribute("AUCTION_BID_LIST", bidListOutput);

            // 입찰 처리 후 세션에 저장된 메시지를 한 번만 화면으로 넘긴다.
            Object bidMessage = data.getSession().getAttribute("AUCTION_BID_MESSAGE");

            if (bidMessage != null) {
                view.setAttribute("AUCTION_BID_MESSAGE", bidMessage.toString());
                data.getSession().removeAttribute("AUCTION_BID_MESSAGE");
            }

            Object bidErrorCode = data.getSession().getAttribute("AUCTION_BID_ERROR_CODE");

            if (bidErrorCode != null) {
                view.setAttribute("AUCTION_BID_ERROR_CODE", bidErrorCode.toString());
                data.getSession().removeAttribute("AUCTION_BID_ERROR_CODE");
            }

            view.setTemplatePage("view/auction/detail");

        } catch (Exception e) {
            throw new RuntimeException("경매 상품 상세 조회 중 오류가 발생했습니다.", e);
        }
    }

    // ============================================================
    // 4. 상세 실시간 조회
    // ============================================================

    @UrlMapping(value = "/realtime", method = "GET")
    public void auctionRealtime(RequestData data, ViewMeta view, HttpServletResponse response) {
        view.disable();

        try {
            // 1. 경매번호 확인
            Long auctionNo = parsePositiveLong(data.getParameters().getText("A_NO"));

            if (auctionNo == null) {
                writeJsonResponse(response,
                    HttpServletResponse.SC_BAD_REQUEST,
                    "{\"result\":\"INVALID_A_NO\"}"
                );
                return;
            }

            // 2. DB 최신 상태 조회
            DataSet detailOutput = auctionService.auctionSelectDetail(auctionNo);

            if (detailOutput == null || detailOutput.getCount("A_NO") == 0) {
                writeJsonResponse(response,
                    HttpServletResponse.SC_NOT_FOUND,
                    "{\"result\":\"AUCTION_NOT_FOUND\"}"
                );
                return;
            }

            DataSet bidListOutput = auctionService.auctionSelectBidList(auctionNo);

            long startPrice = detailOutput.getLong("A_START_PRICE", 0);
            long currentPrice = detailOutput.getLong("A_CURRENT_PRICE", 0);
            long bidCount = detailOutput.getLong("A_BID_COUNT", 0);
            String status = detailOutput.getText("A_STATUS", 0);
            String endDatetime = detailOutput.getText("A_END_DATETIME", 0);
            String closedDatetime = detailOutput.getText("A_CLOSED_DATETIME", 0);
            String adminReason = detailOutput.getText("A_ADMIN_REASON", 0);

            long bidUnit = Math.max(startPrice / 10L, 50_000L);

            Long nextBidPrice = null;

            if ("ONGOING".equals(status)) {
                nextBidPrice = bidCount == 0L ? startPrice : currentPrice + bidUnit;
            }

            // 3. 현재 시연 상태 확인
            String demoState = "READY";
            long demoRemainingMillis = 0L;
            long now = System.currentTimeMillis();

            synchronized (BID_DEMO_STATE_MAP) {
                BidDemoState state = BID_DEMO_STATE_MAP.get(auctionNo);

                if (state != null) {
                    if (state.running && now - state.startedAt < BID_DEMO_RUNNING_TIMEOUT_MILLIS) {
                        demoState = "RUNNING";
                    } else if (!state.running && now < state.availableAt) {
                        demoState = "COOLDOWN";
                        demoRemainingMillis = Math.max(0L, state.availableAt - now);
                    } else {
                        // 실행 제한시간이나 쿨타임이 끝난 상태는 더 이상 보관하지 않는다.
                        BID_DEMO_STATE_MAP.remove(auctionNo);
                    }
                }
            }

            // 4. 브라우저에 전달할 JSON 생성
            String serverDatetime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

            StringBuilder json = new StringBuilder();

            json.append("{")
                .append("\"auctionNo\":").append(auctionNo)
                .append(",\"status\":").append(toJsonString(status))
                .append(",\"currentPrice\":").append(currentPrice)
                .append(",\"bidCount\":").append(bidCount)
                .append(",\"bidUnit\":").append(bidUnit)
                .append(",\"nextBidPrice\":");

            if (nextBidPrice == null) {
                json.append("null");
            } else {
                json.append(nextBidPrice);
            }

            json.append(",\"endDatetime\":").append(toJsonString(endDatetime))
                .append(",\"closedDatetime\":").append(toJsonString(closedDatetime))
                .append(",\"adminReason\":").append(toJsonString(adminReason))
                .append(",\"serverDatetime\":").append(toJsonString(serverDatetime))
                .append(",\"demoState\":").append(toJsonString(demoState))
                .append(",\"demoRemainingMillis\":").append(demoRemainingMillis)
                .append(",\"bidList\":[");

            int bidListCount = bidListOutput == null ? 0 : bidListOutput.getCount("BID_NO");

            for (int i = 0; i < bidListCount; i++) {
                if (i > 0) {
                    json.append(",");
                }

                json.append("{")
                    .append("\"bidNo\":").append(bidListOutput.getLong("BID_NO", i))
                    .append(",\"memberId\":").append(toJsonString(bidListOutput.getText("M_ID", i)))
                    .append(",\"bidPrice\":").append(bidListOutput.getLong("BID_PRICE", i))
                    .append(",\"bidDatetime\":").append(toJsonString(bidListOutput.getText("BID_DATETIME", i)))
                    .append("}");
            }

            json.append("]}");

            writeJsonResponse(response, HttpServletResponse.SC_OK, json.toString());

        } catch (Exception e) {
            logError("AUCTION REALTIME LOAD FAILED", e);

            if (!response.isCommitted()) {
                writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"REALTIME_LOAD_FAILED\"}");
            }
        }
    }

    // ============================================================
    // 5. 일반 입찰
    // ============================================================
    @UrlMapping("/bid")
    public void auctionBid(RequestData data, ViewMeta view) {
        Long auctionNo = null;
        String bidRequestId = null;
        boolean bidFlowStarted = false;

        try {
            // 1. 로그인 확인
            Long loginMemberNo = getLoginMemberNo(data);

            if (loginMemberNo == null) {
                view.setRedirectUrl("../member/loginForm");
                return;
            }

            // 2. 요청값 검증
            DataSet params = data.getParameters();

            auctionNo = parsePositiveLong(params.getText("A_NO"));
            Long bidPrice = parsePositiveLong(params.getText("BID_PRICE"));
            bidRequestId = params.getText("BID_REQUEST_ID");

            if (auctionNo == null) {
                throw new IllegalArgumentException("경매 번호가 올바르지 않습니다.");
            }

            if (bidPrice == null) {
                throw new IllegalArgumentException("입찰 금액이 올바르지 않습니다.");
            }

            if (bidRequestId == null || bidRequestId.isBlank()) {
                throw new IllegalArgumentException("입찰 요청 번호가 생성되지 않았습니다.");
            }

            bidRequestId = bidRequestId.trim();

            if (bidRequestId.length() != 36) {
                throw new IllegalArgumentException("입찰 요청 번호 길이가 올바르지 않습니다. 현재 길이: " + bidRequestId.length());
            }

            try {
                UUID.fromString(bidRequestId);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("입찰 요청 번호가 UUID 형식이 아닙니다.");
            }

            // 3. 시각화 시작 알림
            bidFlowStarted = safeBroadcastToAuction(auctionNo, "BID_FLOW_REQUESTED" + "|A_NO=" + auctionNo + "|REQUEST_ID=" + bidRequestId);

            // 4. 실제 입찰
            auctionService.auctionBid(auctionNo, loginMemberNo, bidPrice, bidRequestId);

            // 5. 성공 알림 + 화면 최신화 알림
            safeBroadcastToAuction(auctionNo, "BID_FLOW_RESOLVED" + "|A_NO=" + auctionNo + "|REQUEST_ID=" + bidRequestId + "|RESULT=SUCCESS");

            safeBroadcastToAuction(auctionNo, "BID_UPDATED|A_NO=" + auctionNo);

            data.getSession().setAttribute("AUCTION_BID_MESSAGE", "입찰이 완료되었습니다.");

            view.setRedirectUrl("detail?A_NO=" + auctionNo);

        } catch (BidException e) {
            broadcastRejectedBidFlow(auctionNo, bidRequestId, bidFlowStarted, e.getCode());
            data.getSession().setAttribute("AUCTION_BID_ERROR_CODE", e.getCode());
            data.getSession().setAttribute("AUCTION_BID_MESSAGE", e.getMessage());

            if (auctionNo == null) {
                view.setRedirectUrl("../main");
            } else {
                view.setRedirectUrl("detail?A_NO=" + auctionNo);
            }

        } catch (IllegalArgumentException e) {
            broadcastRejectedBidFlow(auctionNo, bidRequestId, bidFlowStarted, "INVALID_REQUEST");
            data.getSession().setAttribute("AUCTION_BID_ERROR_CODE", "INVALID_REQUEST");
            data.getSession().setAttribute("AUCTION_BID_MESSAGE", e.getMessage());
            if (auctionNo == null) {
                view.setRedirectUrl("../main");
            } else {
                view.setRedirectUrl("detail?A_NO=" + auctionNo);
            }
        } catch (Exception e) {
            broadcastRejectedBidFlow(auctionNo, bidRequestId, bidFlowStarted, "PROCESS_ERROR");
            logError("BID PROCESS FAILED A_NO=" + auctionNo, e);
            data.getSession().setAttribute("AUCTION_BID_ERROR_CODE", BidException.BID_PROCESS_FAILED);
            data.getSession().setAttribute("AUCTION_BID_MESSAGE", "입찰 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.");

            if (auctionNo == null) {
                view.setRedirectUrl("../main");
            } else {
                view.setRedirectUrl("detail?A_NO=" + auctionNo);
            }
        }
    }

    // ============================================================
    // 6. 동시 입찰 시연 시작
    // ============================================================
    @UrlMapping(value = "/bidDemoStart", method = "POST")
    public void auctionBidDemoStart(RequestData data, ViewMeta view, HttpServletResponse response) {
        view.disable();

        Long auctionNo = null;
        String demoId = null;

        try {
            // 1. 로그인 확인
            if (getLoginMemberNo(data) == null) {
                writeJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "{\"result\":\"LOGIN_REQUIRED\"}");
                return;
            }

            // 2. 요청값 검증
            DataSet params = data.getParameters();

            auctionNo = parsePositiveLong(params.getText("A_NO"));
            Long requestCount = parsePositiveLong(params.getText("REQUEST_COUNT"));
            demoId = params.getText("DEMO_ID");

            if (auctionNo == null || requestCount == null || demoId == null || demoId.isBlank()) {
                throw new IllegalArgumentException("동시 입찰 시연 시작 정보가 올바르지 않습니다.");
            }

            demoId = demoId.trim();

            try {
                UUID.fromString(demoId);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("동시 입찰 시연 번호가 UUID 형식이 아닙니다.");
            }

            // 3. 같은 경매에서 이미 시연 중인지 확인
            String startResult = "SUCCESS";
            long remainingMillis = 0L;
            long now = System.currentTimeMillis();

            synchronized (BID_DEMO_STATE_MAP) {
                BidDemoState currentState = BID_DEMO_STATE_MAP.get(auctionNo);

                if (currentState != null && currentState.running && now - currentState.startedAt < BID_DEMO_RUNNING_TIMEOUT_MILLIS) {
                    startResult = "DEMO_ALREADY_RUNNING";
                } else if (currentState != null && !currentState.running && now < currentState.availableAt) {
                    startResult = "DEMO_COOLDOWN";
                    remainingMillis = Math.max(0L, currentState.availableAt - now);
                } else {
                    BID_DEMO_STATE_MAP.put(auctionNo, new BidDemoState(demoId, true, now, 0L));
                }
            }

            if ("DEMO_ALREADY_RUNNING".equals(startResult)) {
                writeJsonResponse(response, HttpServletResponse.SC_CONFLICT, "{\"result\":\"DEMO_ALREADY_RUNNING\"}");
                return;
            }

            if ("DEMO_COOLDOWN".equals(startResult)) {
                writeJsonResponse(response, HttpServletResponse.SC_CONFLICT, "{\"result\":\"DEMO_COOLDOWN\",\"remainingMillis\":" + remainingMillis + "}");
                return;
            }

            // 4. 같은 상세화면을 보고 있는 모든 브라우저에 시연 시작 알림
            boolean broadcasted = safeBroadcastToAuction(auctionNo, "BID_DEMO_STARTED" + "|A_NO=" + auctionNo + "|DEMO_ID=" + demoId + "|COUNT=" + requestCount);

            if (!broadcasted) {
                // 시작 알림 자체가 실패하면 서버에 잡아둔 시연 상태도 되돌린다.
                synchronized (BID_DEMO_STATE_MAP) {
                    BidDemoState currentState = BID_DEMO_STATE_MAP.get(auctionNo);

                    if (currentState != null && currentState.running && demoId.equals(currentState.demoId)) {
                        BID_DEMO_STATE_MAP.remove(auctionNo);
                    }
                }
                writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"WS_BROADCAST_FAILED\"}");
                return;
            }

            writeJsonResponse(response, HttpServletResponse.SC_OK, "{\"result\":\"SUCCESS\"}");
        } catch (IllegalArgumentException e) {
            writeJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST, "{\"result\":\"INVALID_REQUEST\",\"message\":" + toJsonString(e.getMessage()) + "}");
        } catch (Exception e) {
            logError("BID DEMO START FAILED A_NO=" + auctionNo + ", DEMO_ID=" + demoId, e);
            writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"PROCESS_ERROR\"}");
        }
    }

    // ============================================================
    // 7. 동시 입찰 시연 종료
    // ============================================================
    @UrlMapping(value = "/bidDemoFinish", method = "POST")
    public void auctionBidDemoFinish(RequestData data, ViewMeta view, HttpServletResponse response) {
        view.disable();

        try {
            // 1. 로그인 확인
            if (getLoginMemberNo(data) == null) {
                writeJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "{\"result\":\"LOGIN_REQUIRED\"}");
                return;
            }

            // 2. 요청값 검증
            DataSet params = data.getParameters();

            Long auctionNo = parsePositiveLong(params.getText("A_NO"));
            Long successCount = parseNonNegativeLong(params.getText("SUCCESS_COUNT"));
            Long rejectedCount = parseNonNegativeLong(params.getText("REJECTED_COUNT"));
            String demoId = params.getText("DEMO_ID");

            if (auctionNo == null || successCount == null || rejectedCount == null || demoId == null || demoId.isBlank()) {
                throw new IllegalArgumentException("동시 입찰 시연 종료 정보가 올바르지 않습니다.");
            }

            demoId = demoId.trim();

            try {
                UUID.fromString(demoId);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("동시 입찰 시연 번호가 UUID 형식이 아닙니다."
                );
            }

            // 3. RUNNING 상태를 COOLDOWN 상태로 변경
            boolean finished = false;
            long now = System.currentTimeMillis();

            synchronized (BID_DEMO_STATE_MAP) {
                BidDemoState currentState = BID_DEMO_STATE_MAP.get(auctionNo);

                if (currentState != null && currentState.running && demoId.equals(currentState.demoId)) {
                    currentState.running = false;
                    currentState.availableAt = now + BID_DEMO_COOLDOWN_MILLIS;
                    finished = true;
                }
            }

            if (!finished) {
                writeJsonResponse(response, HttpServletResponse.SC_CONFLICT, "{\"result\":\"DEMO_STATE_MISMATCH\"}");
                return;
            }

            // 4. 모든 브라우저에 시연 결과와 쿨타임 알림
            boolean broadcasted = safeBroadcastToAuction(auctionNo,
                "BID_DEMO_FINISHED"
                    + "|A_NO=" + auctionNo
                    + "|DEMO_ID=" + demoId
                    + "|SUCCESS=" + successCount
                    + "|REJECTED=" + rejectedCount
                    + "|COOLDOWN_MS=" + BID_DEMO_COOLDOWN_MILLIS
            );

            if (!broadcasted) {
                writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"WS_BROADCAST_FAILED\"}");
                return;
            }

            writeJsonResponse(response, HttpServletResponse.SC_OK, "{\"result\":\"SUCCESS\",\"cooldownMillis\":" + BID_DEMO_COOLDOWN_MILLIS + "}");
        } catch (IllegalArgumentException e) {
            writeJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST, "{\"result\":\"INVALID_REQUEST\",\"message\":" + toJsonString(e.getMessage()) + "}");
        } catch (Exception e) {
            logError("BID DEMO FINISH FAILED", e);
            writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"PROCESS_ERROR\"}");
        }
    }

    // ============================================================
    // 8. 발표용 실제 단일 입찰 요청
    // ============================================================
    @UrlMapping(value = "/bidDemoSingle", method = "POST")
    public void auctionBidDemoSingle(RequestData data, ViewMeta view, HttpServletResponse response) {
        view.disable();

        Long auctionNo = null;
        String bidRequestId = null;

        try {
            // 1. 로그인 확인
            Long loginMemberNo = getLoginMemberNo(data);

            if (loginMemberNo == null) {
                writeJsonResponse(response, HttpServletResponse.SC_UNAUTHORIZED, "{\"result\":\"LOGIN_REQUIRED\"," + "\"message\":\"로그인 후 시연해 주세요.\"}");
                return;
            }

            // 2. 요청값 검증
            DataSet params = data.getParameters();

            auctionNo = parsePositiveLong(params.getText("A_NO"));
            Long bidPrice = parsePositiveLong(params.getText("BID_PRICE"));
            bidRequestId = params.getText("BID_REQUEST_ID");

            if (auctionNo == null || bidPrice == null || bidRequestId == null) {
                throw new IllegalArgumentException("동시 요청 시연 정보가 올바르지 않습니다.");
            }

            bidRequestId = bidRequestId.trim();

            if (bidRequestId.length() != 36) {
                throw new IllegalArgumentException("입찰 요청 번호 길이가 올바르지 않습니다.");
            }

            try {
                UUID.fromString(bidRequestId);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("입찰 요청 번호가 UUID 형식이 아닙니다.");
            }

            // 3. 실제 DB 입찰
            auctionService.auctionBid(auctionNo, loginMemberNo, bidPrice, bidRequestId);

            // 4. 성공한 경우 실제 경매 데이터가 바뀌었다고 알림
            safeBroadcastToAuction(auctionNo, "BID_UPDATED|A_NO=" + auctionNo);
            writeJsonResponse(response, HttpServletResponse.SC_OK, "{\"result\":\"SUCCESS\",\"requestId\":" + toJsonString(bidRequestId) + "}");

        } catch (BidException e) {
            writeJsonResponse(response,  HttpServletResponse.SC_OK, "{\"result\":\"REJECTED\",\"requestId\":" + toJsonString(bidRequestId) + ",\"reason\":" + toJsonString(e.getCode()) + "}");
        } catch (IllegalArgumentException e) {
            writeJsonResponse(response, HttpServletResponse.SC_BAD_REQUEST, "{\"result\":\"REJECTED\",\"requestId\":" + toJsonString(bidRequestId) + ",\"reason\":\"INVALID_REQUEST\"" + ",\"message\":" + toJsonString(e.getMessage()) + "}");
        } catch (Exception e) {
            logError("BID DEMO SINGLE FAILED A_NO=" + auctionNo + ", REQUEST_ID=" + bidRequestId, e);
            writeJsonResponse(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "{\"result\":\"REJECTED\",\"requestId\":" + toJsonString(bidRequestId) + ",\"reason\":\"PROCESS_ERROR\"" + ",\"message\":\"동시 요청 시연 중 오류가 발생했습니다.\"}");
        }
    }

    // ============================================================
    // 9. 저장 이미지 조회
    // ============================================================
    @UrlMapping(value = "/image", method = "GET")
    public void auctionImage(RequestData data, ViewMeta view, HttpServletResponse response) {
        view.disable();

        try {
            // 1. 파일명 검증
            String storedFileName = data.getParameters().getText("IMG_STORED_NAME");

            if (storedFileName == null || storedFileName.isBlank()) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            storedFileName = storedFileName.trim();

            if (storedFileName.contains("/") || storedFileName.contains("\\") || storedFileName.contains("..")) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            // 2. 실제 이미지 경로 생성
            if (auctionImagePath == null || auctionImagePath.isBlank()) {
                throw new IllegalStateException("auction.image.path 설정이 없습니다.");
            }

            Path imageDirectory = Path.of(auctionImagePath.trim()).toAbsolutePath().normalize();
            Path imagePath = imageDirectory.resolve(storedFileName).normalize();

            // 상위 디렉터리로 빠져나가는 경로 접근 방지
            if (!imagePath.startsWith(imageDirectory)) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            if (!Files.isRegularFile(imagePath) || !Files.isReadable(imagePath)) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            // 3. Content-Type 확인
            String contentType = URLConnection.guessContentTypeFromName(storedFileName);

            if (contentType == null || contentType.isBlank()) {
                contentType = Files.probeContentType(imagePath);
            }

            if (contentType == null || contentType.isBlank()) {
                contentType = "application/octet-stream";
            }

            // 4. 이미지 응답
            response.reset();
            response.setStatus(HttpServletResponse.SC_OK);
            response.setContentType(contentType);
            response.setContentLengthLong(Files.size(imagePath));
            response.setHeader("X-Content-Type-Options", "nosniff");
            response.setHeader("Cache-Control", "public, max-age=86400");

            Files.copy(imagePath, response.getOutputStream());
            response.getOutputStream().flush();

        } catch (Exception e) {
            logError("AUCTION IMAGE LOAD FAILED", e);
            if (!response.isCommitted()) {
                response.reset();
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            }
        }
    }

    // ============================================================
    // 공통 기능
    // 정말 여러 곳에서 반복되는 기능만 메서드로 분리한다.
    // ============================================================
    private Long getLoginMemberNo(RequestData data) {
        Object loginMemberNo = data.getSession().getAttribute("LOGIN_MEMBER_NO");

        if (loginMemberNo == null) {
            return null;
        }

        if (loginMemberNo instanceof Number) {
            return ((Number) loginMemberNo).longValue();
        }

        try {
            return Long.parseLong(loginMemberNo.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parsePositiveLong(String value) {
        if (value == null) {
            return null;
        }

        try {
            long parsedValue = Long.parseLong(value.replace(",", "").trim());
            return parsedValue > 0L ? parsedValue : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parseNonNegativeLong(String value) {
        if (value == null) {
            return null;
        }

        try {
            long parsedValue = Long.parseLong(value.replace(",", "").trim());
            return parsedValue >= 0L ? parsedValue : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String normalizeSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return "LATEST";
        }

        String normalizedSort = sort.trim().toUpperCase(Locale.ROOT);

        switch (normalizedSort) {
            case "LATEST":
            case "OLDEST":
            case "PRICE_HIGH":
            case "PRICE_LOW":
                return normalizedSort;

            default:
                return "LATEST";
        }
    }

    private void broadcastRejectedBidFlow(Long auctionNo, String bidRequestId, boolean bidFlowStarted, String reason) {
        if (!bidFlowStarted || auctionNo == null || bidRequestId == null || bidRequestId.isBlank()) {
            return;
        }

        if (reason == null || reason.isBlank()) {
            reason = "REJECTED";
        } else {
            reason = reason.replace("|", "_").replace("=", "_");
        }

        safeBroadcastToAuction(auctionNo, "BID_FLOW_RESOLVED" + "|A_NO=" + auctionNo + "|REQUEST_ID=" + bidRequestId + "|RESULT=REJECTED" + "|REASON=" + reason);
    }

    private boolean safeBroadcastToAuction(Long auctionNo, String message) {
        if (auctionNo == null || message == null || message.isBlank()) {
            return false;
        }
        
        try {
            AuctionWebSocketManager.broadcastToAuction(auctionNo, message);
            return true;
        } catch (RuntimeException e) {
            logError("AUCTION WS BROADCAST ERROR A_NO=" + auctionNo + ", MESSAGE=" + message, e);
            return false;
        }
    }

    private String toJsonString(String value) {
        if (value == null) {
            return "\"\"";
        }

        StringBuilder escapedValue = new StringBuilder("\"");

        for (int i = 0; i < value.length(); i++) {
            char character = value.charAt(i);

            switch (character) {
                case '"': escapedValue.append("\\\""); break;
                case '\\': escapedValue.append("\\\\"); break;
                case '\b': escapedValue.append("\\b"); break;
                case '\f': escapedValue.append("\\f"); break;
                case '\n': escapedValue.append("\\n"); break;
                case '\r': escapedValue.append("\\r"); break;
                case '\t': escapedValue.append("\\t"); break;

                default:
                    if (character < 0x20) {
                        escapedValue.append(String.format("\\u%04x", (int) character));
                    } else {
                        escapedValue.append(character);
                    }
                    break;
            }
        }

        return escapedValue.append("\"").toString();
    }

    private void writeJsonResponse(HttpServletResponse response, int status, String json) {
        try {
            response.reset();
            response.setStatus(status);
            response.setCharacterEncoding("UTF-8");
            response.setContentType("application/json; charset=UTF-8");
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.setHeader("Pragma", "no-cache");
            response.getWriter().write(json);
            response.getWriter().flush();
        } catch (IOException e) {
            throw new RuntimeException("JSON 응답 작성에 실패했습니다.", e);
        }
    }

    private void logError(String message, Exception e) {
        System.err.println("[" + message + "]" + " EXCEPTION=" + e.getClass().getName() + ", MESSAGE=" + e.getMessage());
        e.printStackTrace();
    }
}