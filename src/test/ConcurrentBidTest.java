package test;

import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

//AuctionFlow 입찰 동시성 테스트를 위한 클래스입니다.
public class ConcurrentBidTest {

    // ============================================================
    // 테스트 설정
    // ============================================================
    private static final String BASE_URL = "http://localhost:8080/auctionFlow/api/auctionFlow";

    // 테스트할 진행중인 경매번호
    private static final long AUCTION_NO = 7L;

    // 경매 판매자가 아닌 일반회원
    private static final String MEMBER_ID = "1111";
    private static final String MEMBER_PW = "1111";

    // 동시에 발생시킬 요청 수
    private static final int REQUEST_COUNT = 100;
    private static final CookieManager COOKIE_MANAGER = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
    private static final HttpClient CLIENT = HttpClient.newBuilder().cookieHandler(COOKIE_MANAGER).followRedirects(HttpClient.Redirect.NORMAL).connectTimeout(Duration.ofSeconds(5)).build();

    public static void main(String[] args) throws Exception {
        System.out.println("========================================");
        System.out.println(" AuctionFlow 동시 입찰 자동 테스트");
        System.out.println("========================================");

        // --------------------------------------------------------
        // 1. 로그인
        // --------------------------------------------------------
        login();

        System.out.println("[1] 로그인 성공");


        // --------------------------------------------------------
        // 2. 테스트 전 DB 상태 조회
        // --------------------------------------------------------
        Snapshot before = loadSnapshot();

        System.out.println();
        System.out.println("[2] 테스트 전 상태");
        printSnapshot(before);

        if (!"ONGOING".equals(before.status())) {
            throw new AssertionError("테스트 실패: 진행중인 경매가 아닙니다. status=" + before.status());
        }

        if (before.nextBidPrice() == null) {
            throw new AssertionError("테스트 실패: 다음 입찰가를 조회하지 못했습니다.");
        }
        
        //테스트 시작 전 DB에서 현재 입찰 가능 금액 조회
        long testBidPrice = before.nextBidPrice();

        System.out.println();
        System.out.println("동시 입찰 가격: " + testBidPrice);
        System.out.println("동시 요청 개수: " + REQUEST_COUNT);

 
        //N개 Thread 준비
        ExecutorService executor = Executors.newFixedThreadPool(REQUEST_COUNT);
        CountDownLatch readyLatch = new CountDownLatch(REQUEST_COUNT);
        CountDownLatch startLatch = new CountDownLatch(1);
        List<Future<BidResult>> futures = new ArrayList<>();

        for (int i = 0; i < REQUEST_COUNT; i++) {
            futures.add(executor.submit(() -> {
            	    // 현재 Thread 준비 완료
                    readyLatch.countDown();
                    // 시작 Gate가 열릴 때까지 대기
                    startLatch.await();
                    // 동일한 입찰가격으로 실제 HTTP 요청
                    return sendBid(testBidPrice);
                }));
        }

        //모든 Thread가 준비 완료될 때까지 대기
        readyLatch.await();

        System.out.println();
        System.out.println("[3] " + REQUEST_COUNT + "개 요청 준비 완료");

        long startTime = System.currentTimeMillis();

        //대기 중인 모든 Thread를 동시에 실행 가능 상태로 전환
        startLatch.countDown();


        // --------------------------------------------------------
        // 5. 결과 집계
        // --------------------------------------------------------
        int successCount = 0;
        int rejectedCount = 0;
        int errorCount = 0;

        for (Future<BidResult> future : futures) {

            BidResult result = future.get();

            switch (result.result()) {
                case "SUCCESS": successCount++;
                    break;

                case "REJECTED": rejectedCount++;
                    break;

                default: errorCount++;
                    System.out.println("비정상 응답: " + result.body());
            }
        }

        executor.shutdown();

        long elapsed = System.currentTimeMillis() - startTime;


        System.out.println();
        System.out.println("[4] HTTP 요청 결과");
        System.out.println("SUCCESS  : " + successCount);
        System.out.println("REJECTED : " + rejectedCount);
        System.out.println("ERROR    : " + errorCount);
        System.out.println("소요시간 : " + elapsed + " ms");


        // --------------------------------------------------------
        // 6. 테스트 후 DB 상태 다시 조회
        // --------------------------------------------------------
        Snapshot after = loadSnapshot();

        System.out.println();
        System.out.println("[5] 테스트 후 상태");
        printSnapshot(after);


        // --------------------------------------------------------
        // 7. 자동 검증
        // --------------------------------------------------------
        System.out.println();
        System.out.println("[6] 검증 시작");


        assertEquals(1, successCount, "성공 요청 수");

        assertEquals(REQUEST_COUNT - 1, rejectedCount, "거절 요청 수");

        assertEquals(0, errorCount, "HTTP 오류 수");

        assertEquals(before.bidCount() + 1, after.bidCount(), "AUCTION 입찰 건수");
        assertEquals(before.bidListCount() + 1, after.bidListCount(), "BID 테이블 실제 행 증가");
        
        assertEquals(testBidPrice, after.currentPrice(), "최종 현재가");


        System.out.println();
        System.out.println("========================================");
        System.out.println("          ALL TEST PASSED");
        System.out.println("========================================");
    }


    // ============================================================
    // 로그인
    // ============================================================
    private static void login() throws Exception {

        String form = "M_ID=" + encode(MEMBER_ID) + "&M_PW=" + encode(MEMBER_PW);

        HttpRequest request = HttpRequest.newBuilder().uri(URI.create(BASE_URL + "/member/login")).header("Content-Type", "application/x-www-form-urlencoded").POST(HttpRequest.BodyPublishers.ofString(form)).build();

        HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());

        // 정상 로그인 시 main으로 redirect됨
        if (!response.uri().getPath().endsWith("/main")) {
            throw new AssertionError("로그인 실패 가능성이 있습니다. 최종 URL: " + response.uri());
        }
    }


    //실제 입찰 HTTP 요청
    private static BidResult sendBid(long bidPrice) throws Exception {
        String requestId = UUID.randomUUID().toString();
        String form = "A_NO=" + AUCTION_NO + "&BID_PRICE=" + bidPrice + "&BID_REQUEST_ID=" + encode(requestId);

        HttpRequest request =
                HttpRequest.newBuilder()
                        .uri(URI.create(
                                BASE_URL
                                + "/auction/bidDemoSingle"
                        ))
                        .header(
                                "Content-Type",
                                "application/x-www-form-urlencoded"
                        ).header("Accept", "application/json").POST(HttpRequest.BodyPublishers.ofString(form)).build();

        HttpResponse<String> response =
                CLIENT.send(
                        request,
                        HttpResponse.BodyHandlers.ofString()
                );

        String body = response.body();

        String result = extractString(body, "result");

        return new BidResult(response.statusCode(), result, body);
    }


    // ============================================================
    // realtime API를 사용해서 실제 DB 결과 조회
    // ============================================================
    private static Snapshot loadSnapshot()
            throws Exception {

        String url = BASE_URL + "/auction/realtime?A_NO=" + AUCTION_NO;

        HttpRequest request =
                HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .GET()
                        .build();

        HttpResponse<String> response =
                CLIENT.send(
                        request,
                        HttpResponse.BodyHandlers.ofString()
                );

        if (response.statusCode() != 200) {

            throw new AssertionError(
                    "realtime 조회 실패: HTTP "
                            + response.statusCode()
            );
        }

        String json = response.body();

        String status = extractString(json, "status");

        long currentPrice = extractLong(json, "currentPrice");

        long bidCount = extractLong(json, "bidCount");

        Long nextBidPrice = extractNullableLong(json, "nextBidPrice");

        /*
         * realtime의 bidList는
         * KYH_AF_AUCTION_BID 조회 결과다.
         *
         * 따라서 bidNo 개수를 세면
         * 실제 BID 테이블 행 개수를 확인할 수 있다.
         */
        int bidListCount = countOccurrences(json, "\"bidNo\":");

        return new Snapshot(status, currentPrice, bidCount, nextBidPrice, bidListCount);
    }


    // ============================================================
    // 검증
    // ============================================================
    private static void assertEquals(long expected, long actual,String description) {
        if (expected != actual) {
            throw new AssertionError(description + " 검증 실패"  + " / expected=" + expected + ", actual=" + actual);
        }
        System.out.println("[PASS] " + description + " = " + actual);
    }


    // ============================================================
    // 출력
    // ============================================================
    private static void printSnapshot(Snapshot snapshot) {
        System.out.println("상태          : " + snapshot.status());
        System.out.println("현재가        : " + snapshot.currentPrice());
        System.out.println("A_BID_COUNT   : " + snapshot.bidCount());
        System.out.println("BID 실제 건수 : " + snapshot.bidListCount());
        System.out.println("다음 입찰가   : " + snapshot.nextBidPrice());
    }


    // ============================================================
    // 간단한 JSON 값 추출
    // 외부 JSON 라이브러리를 추가하지 않기 위해 테스트용으로 사용
    // ============================================================
    private static String extractString(String json, String key) {

        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*\"([^\"]*)\"");

        Matcher matcher = pattern.matcher(json);

        if (!matcher.find()) {
            return "";
        }
        return matcher.group(1);
    }


    private static long extractLong(String json, String key) {

        Long value = extractNullableLong(json, key);

        if (value == null) {
            throw new IllegalStateException(key + " 값을 찾을 수 없습니다.");
        }
        return value;
    }


    private static Long extractNullableLong(String json, String key) {

        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*(null|\\d+)");

        Matcher matcher = pattern.matcher(json);

        if (!matcher.find()) {
            return null;
        }

        if ("null".equals(matcher.group(1))) {
            return null;
        }
        return Long.parseLong(matcher.group(1));
    }

    private static int countOccurrences(String text, String target) {
        int count = 0;
        int index = 0;

        while ((index = text.indexOf(target, index)) >= 0) {
            count++;
            index += target.length();
        }

        return count;
    }


    private static String encode(String value) {
        return URLEncoder.encode( value, StandardCharsets.UTF_8);
    }

    // ============================================================
    // 결과 DTO
    // ============================================================

    private record BidResult(int statusCode, String result, String body) {
    }

    private record Snapshot(String status, long currentPrice, long bidCount, Long nextBidPrice, int bidListCount) {
    }
}