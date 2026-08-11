package auctionFlow.service;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import auctionFlow.exception.BidException;
import coreframe.annotations.beans.Bean;
import coreframe.annotations.beans.Property;
import coreframe.data.DataSet;
import coreframe.data.Interaction;
import coreframe.data.InteractionFactory;
import coreframe.http.MultipartFile;

@Bean
public class AuctionService {
	
	//이미지 저장 경로(config에서 설정)
	@Property("auction.image.path")
	private String auctionImagePath;
	
	//1. 경매 상품 등록
	public long auctionRegister(long memberNo, String auctionCategory, String auctionTitle, String auctionContent, long auctionStartPrice, String auctionEndDatetime, MultipartFile mainImage, List<MultipartFile> subImages) throws Exception {
		
		DataSet auctionInput = DataSet.newDefault();
		auctionInput.put("M_NO", memberNo);
		auctionInput.put("A_CATEGORY", auctionCategory);
		auctionInput.put("A_TITLE", auctionTitle);
		auctionInput.put("A_CONTENT", auctionContent);
		auctionInput.put("A_START_PRICE", auctionStartPrice);
		auctionInput.put("A_CURRENT_PRICE", auctionStartPrice);
		auctionInput.put("A_STATUS", "ONGOING");
		auctionInput.put("A_END_DATETIME", auctionEndDatetime);
		
		Interaction interaction = InteractionFactory.getInteraction();

			DataSet auctionOutput = interaction.execute("auction/register", auctionInput);

			long auctionNo = auctionOutput.getLong("A_NO");

			List<File> savedFiles = new ArrayList<>();

			try {

				File storedDirectory = getAuctionImageStoreDirectory();

				// 대표 이미지 저장
				saveAuctionImage(interaction, auctionNo, "MAIN", mainImage, storedDirectory, savedFiles);

				// 추가 이미지 저장
				if (subImages != null) {

					for (MultipartFile subImage : subImages) {

						if (subImage == null || subImage.isEmpty()) {
							continue;
						}
						saveAuctionImage(interaction, auctionNo, "SUB", subImage, storedDirectory, savedFiles);
					}
				}
				return auctionNo;
			} catch (Exception e) {
				rollbackAuctionRegister(interaction, auctionNo, savedFiles);
				throw e;
		}
	}
	
	//2. 이미지 파일 저장 + 이미지 정보 DB 저장
	private void saveAuctionImage(Interaction interaction, long auctionNo, String imageType, MultipartFile multipartFile, File storedDirectory, List<File> savedFiles) throws Exception {
		
		if (multipartFile == null || multipartFile.isEmpty()) {
			throw new RuntimeException("이미지 파일이 비어 있습니다.");
		}
		
		String originalFileName = cleanOriginalFileName(multipartFile.getOriginalFilename());
		String extension = getFileExtension(originalFileName);
		String storedFileName = imageType + "_" + auctionNo + "_" + UUID.randomUUID().toString().replace("-", "") + extension;
		
		File storedFile = new File(storedDirectory, storedFileName);
		
		boolean isFileSaved = false;
		
		try {
			multipartFile.transferTo(storedFile);
			
			isFileSaved = true;
			
			DataSet imageInput = DataSet.newDefault();
			imageInput.put("A_NO", auctionNo);
			imageInput.put("IMG_TYPE", imageType);
			imageInput.put("IMG_ORIGINAL_NAME", originalFileName);
			imageInput.put("IMG_STORED_NAME", storedFileName);
			
			interaction.execute("auction/registerImage", imageInput);
			
			savedFiles.add(storedFile);
		} catch (Exception e) {
			if (isFileSaved && storedFile.exists()) {
				storedFile.delete();
			}
			throw e;
		}
	}
	
	//2-1.원본 파일명 정리
	private String cleanOriginalFileName(String originalFileName) {
		
		if (originalFileName == null || originalFileName.isBlank()) {
			throw new RuntimeException("원본 파일명이 없습니다.");
		}
		
		String cleanedFileName = originalFileName.replace("\\", "/");
		
		int lastSlashIndex = cleanedFileName.lastIndexOf("/");
		
		if (lastSlashIndex >= 0) {
			cleanedFileName = cleanedFileName.substring(lastSlashIndex + 1);
		}
		return cleanedFileName;
	}
	
	//2++.확장자 추출
	private String getFileExtension(String originalFileName) {
		
		int lastDotIndex = originalFileName.lastIndexOf(".");
		
		if (lastDotIndex < 0 || lastDotIndex == originalFileName.length() - 1) {
			throw new RuntimeException("이미지 파일 확장자를 확인할 수 없습니다.");
		}
		return originalFileName.substring(lastDotIndex).toLowerCase();
	}
	
	//모종의 이유로 상품 등록 실패했는데 DB에 값이 들어갈 경우 삭제하는 메서드
	private void rollbackAuctionRegister(Interaction interaction, long auctionNo, List<File> savedFiles) {

			try {
				DataSet rollbackInput = DataSet.newDefault();
				rollbackInput.put("A_NO", auctionNo);
				interaction.execute("auction/deleteByAuctionNo", rollbackInput);
			} catch (Exception e) {
				e.printStackTrace();
			}

			if (savedFiles != null) {
				for (File savedFile : savedFiles) {
					if (savedFile != null && savedFile.exists()) {
						boolean isDeleted = savedFile.delete();
						if (!isDeleted) {
							System.out.println("이미지 파일 삭제 실패: " + savedFile.getAbsolutePath());
						}
					}
				}
			}
		}
	
	//3. 진행 경매 상품 목록 조회(main.jsp)
	public DataSet auctionSelectList(String sort) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("SORT_LATEST", sort);
		input.put("SORT_OLDEST", sort);
		input.put("SORT_PRICE_HIGH", sort);
		input.put("SORT_PRICE_LOW", sort);
		
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet output = interaction.execute("auction/list", input);
		return output;
	}
	
	//3-1.
	public DataSet auctionSelectList() throws Exception {
		return auctionSelectList("LATEST");
	}
	
	//4. 지난 경매 상품 목록 조회(pastList.jsp)
	public DataSet auctionSelectPastList(String sort) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet closeInput = DataSet.newDefault();
		interaction.execute("auction/closeExpired", closeInput);
		
		DataSet input = DataSet.newDefault();
		input.put("SORT_LATEST", sort);
		input.put("SORT_OLDEST", sort);
		input.put("SORT_PRICE_HIGH", sort);
		input.put("SORT_PRICE_LOW", sort);
		
		DataSet output = interaction.execute("auction/pastList", input);
		return output;
	}
	
	//4-1.
	public DataSet auctionSelectPastList() throws Exception {
		return auctionSelectPastList("LATEST");
	}
	
	//5. 경매 상품 상세정보 조회
	public DataSet auctionSelectDetail(long auctionNo) throws Exception {
		Interaction interaction = InteractionFactory.getInteraction();
		DataSet closeInput = DataSet.newDefault();
		interaction.execute("auction/closeExpired", closeInput);
		
		DataSet input = DataSet.newDefault();
		input.put("A_NO", auctionNo);
		
		DataSet output = interaction.execute("auction/detail", input);
		return output;
	}
	
	//5-1. 경매 상품 입찰 이력 조회
	public DataSet auctionSelectBidList(long auctionNo) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("A_NO", auctionNo);
		Interaction interaction = InteractionFactory.getInteraction();

		DataSet output = interaction.execute("auction/bidList", input);
		return output;
	}
	
	//6. 경매 상품 제목 검색
	public DataSet auctionSearchList(String keyword, String sort) throws Exception {
		
		DataSet input = DataSet.newDefault();
		input.put("KEYWORD", "%" + keyword + "%");
		input.put("SORT_LATEST", sort);
		input.put("SORT_OLDEST", sort);
		input.put("SORT_PRICE_HIGH", sort);
		input.put("SORT_PRICE_LOW", sort);
		
		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet output = interaction.execute("auction/search", input);
		return output;
	}
	
	//6-1.
	public DataSet auctionSearchList(String keyword) throws Exception {
		return auctionSearchList(keyword, "LATEST");
	}
	
	//7. 경매 입찰 처리
	public String auctionBid(long auctionNo, long memberNo, long bidPrice, String bidRequestId) throws Exception {
		
		if (auctionNo <= 0 || memberNo <= 0 || bidPrice <= 0 || bidRequestId == null || bidRequestId.isBlank()) {
			throw new IllegalArgumentException("입찰 정보가 올바르지 않습니다.");
		}
		bidRequestId = bidRequestId.trim();
		
		/*
		 * 사전 검증은 사용자에게 빠르게 오류를 안내하기 위한 보조 검사다.
		 * 동시 입찰의 최종 판정은 auction/bid.bldx에서 SELECT ... FOR UPDATE로 경매 행을 잠근 뒤 다시 수행한다.
		 */
		DataSet beforeCheck = auctionBidCheck(auctionNo, bidRequestId);
		checkAuctionBid(beforeCheck, memberNo, bidPrice, false);
		
		DataSet input = DataSet.newDefault();
		// 비관적 락 획득 및 락 이후 최종 검증에 필요한 값
		input.put("BID_REQUEST_ID_LOCK", bidRequestId);
		input.put("A_NO_LOCK", auctionNo);
		
		// 경매 현재가와 최고 입찰자 갱신
		input.put("BID_PRICE_UPDATE", bidPrice);
		input.put("M_NO_UPDATE", memberNo);
		input.put("A_NO_UPDATE", auctionNo);
		input.put("M_NO_OWNER_UPDATE", memberNo);
		input.put("BID_PRICE_CHECK_UPDATE", bidPrice);
		input.put("BID_REQUEST_ID_CHECK_UPDATE", bidRequestId);
		
		// 입찰 이력 등록
		input.put("A_NO_INSERT", auctionNo);
		input.put("M_NO_INSERT", memberNo);
		input.put("BID_PRICE_INSERT", bidPrice);
		input.put("BID_REQUEST_ID_INSERT", bidRequestId);
		
		// 입찰 처리 결과 조회
		input.put("A_NO_RESULT", auctionNo);
		
		Interaction interaction = InteractionFactory.getInteraction();
		
		DataSet output;
		try {
			output = interaction.execute("auction/bid", input);
		} catch (Exception e) {

			/*
			 * 같은 BID_REQUEST_ID가 동시에 다른 경매 등에서 사용되더라도 DB UNIQUE 제약조건이 마지막 방어선이 된다.
			 * bid.bldx는 하나의 트랜잭션으로 실행되므로 이 경우 UPDATE도 롤백된다.
			 */
			if (isDuplicateBidRequestException(e)) {
				throw new BidException(BidException.DUPLICATE_REQUEST, "이미 처리된 입찰 요청입니다. 최신 입찰 정보를 확인해 주세요.");
			}
			throw e;
		}
		
		if (output == null) {
			throw new BidException(BidException.BID_PROCESS_FAILED, "입찰 처리 결과를 확인하지 못했습니다.");
		}
		
		//lockAuction은 대기 후 최신 커밋 데이터를 읽는다. 따라서 동시에 동일 가격으로 들어온 후속 요청은 여기서 PRICE_CHANGED로 거절된다.
		checkAuctionBid(output, memberNo, bidPrice, true);
		
		long updatedCount = output.getLong("UPDATED_COUNT");
		long insertedCount = output.getLong("INSERTED_COUNT");
		
		if (updatedCount != 1L || insertedCount != 1L) {
			throw new BidException(BidException.BID_PROCESS_FAILED, "입찰 반영 건수가 일치하지 않습니다. 잠시 후 다시 시도해 주세요.");
		}
		
		if (output.getCount("A_CURRENT_PRICE") == 0) {
			throw new BidException(BidException.BID_PROCESS_FAILED, "입찰 처리 결과를 확인하지 못했습니다.");
		}
		
		long beforeBidCount = output.getLong("BEFORE_BID_COUNT");
		long afterBidCount = output.getLong("A_BID_COUNT");
		long savedCurrentPrice = output.getLong("A_CURRENT_PRICE");
		long savedHighestBidderMemberNo = output.getLong("HIGHEST_BIDDER_M_NO");
		String savedHighestBidderMemberId = output.getText("HIGHEST_BIDDER_M_ID");
		
		boolean isBidSuccess = afterBidCount == beforeBidCount + 1
							&& savedCurrentPrice == bidPrice
							&& savedHighestBidderMemberNo == memberNo
							&& savedHighestBidderMemberId != null
							&& !savedHighestBidderMemberId.isBlank();
		if (!isBidSuccess) {
			throw new BidException(BidException.BID_PROCESS_FAILED, "입찰 처리 결과가 요청 정보와 일치하지 않습니다.");
		}
		return savedHighestBidderMemberId;
	}
	
	//8. 입찰 가능 상태 조회
	private DataSet auctionBidCheck(long auctionNo, String bidRequestId) throws Exception {
		DataSet input = DataSet.newDefault();
		input.put("BID_REQUEST_ID_CHECK", bidRequestId);
		input.put("A_NO_CHECK", auctionNo);
		
		Interaction interaction = InteractionFactory.getInteraction();
		return interaction.execute("auction/bidCheck", input);
	}
	
	//9. 입찰 불가 사유 검증
	private void checkAuctionBid(DataSet checkOutput, long memberNo, long bidPrice, boolean isFinalCheck) {
		
		if (checkOutput == null || checkOutput.getCount("A_NO") == 0) {
			throw new BidException(BidException.AUCTION_NOT_FOUND, "해당 경매 상품을 찾을 수 없습니다.");
		}
		
		long duplicateRequestCount = checkOutput.getLong("DUPLICATE_REQUEST_COUNT");
		
		if (duplicateRequestCount > 0) {
			throw new BidException(BidException.DUPLICATE_REQUEST, "이미 처리된 입찰 요청입니다. 최신 입찰 정보를 확인해 주세요.");
		}
		
		long sellerMemberNo = checkOutput.getLong("SELLER_M_NO");
		
		if (sellerMemberNo == memberNo) {
			throw new BidException(BidException.SELF_BID, "본인이 등록한 상품에는 입찰 할 수 없습니다.");
		}
		
		String auctionStatus = checkOutput.getText("A_STATUS");
		
		if (auctionStatus == null) {
			auctionStatus = "";
		}
		
		auctionStatus = auctionStatus.trim().toUpperCase();
		
		if ("CANCELED".equals(auctionStatus)) {
			throw new BidException(BidException.AUCTION_CANCELED, "취소된 경매에는 입찰 할 수 없습니다.");
		}
		
		if (!"ONGOING".equals(auctionStatus)) {
			throw new BidException(BidException.AUCTION_CLOSED, "종료된 경매에는 입찰 할 수 없습니다.");
		}
		
		long isEnded = checkOutput.getLong("IS_ENDED");

		if (isEnded == 1L) {
			throw new BidException(BidException.AUCTION_ENDED, "경매 시간이 종료되어 입찰할 수 없습니다.");
		}

		long expectedBidPrice = checkOutput.getLong("EXPECTED_BID_PRICE");

		if (bidPrice != expectedBidPrice) {
			String formattedExpectedBidPrice = String.format("%,d", expectedBidPrice);

			if (isFinalCheck) {
				throw new BidException(BidException.PRICE_CHANGED, "다른 사용자가 먼저 입찰하여 현재가가 변경되었습니다. " + "현재 응찰 가능 금액은 " + formattedExpectedBidPrice + "원입니다.");
			}
			throw new BidException(BidException.INVALID_BID_PRICE, "현재 응찰 가능 금액은 " + formattedExpectedBidPrice + "원입니다.");
		}
	}
	
	//BID_REQUEST_ID의 UNIQUE 제약조건 오류 확인
	private boolean isDuplicateBidRequestException(Throwable throwable) {
		Throwable currentThrowable = throwable;
		while (currentThrowable != null) {
			String errorMessage = currentThrowable.getMessage();
			if (errorMessage != null) {
				String normalizedMessage = errorMessage.toUpperCase();
				if (normalizedMessage.contains("DUPLICATE ENTRY") && normalizedMessage.contains("BID_REQUEST_ID")) {
					return true;
				}
			}
			currentThrowable = currentThrowable.getCause();
		}
		return false;
	}
	
	//10. 경매 이미지 저장 폴더 준비
	private File getAuctionImageStoreDirectory() throws Exception {

		if (auctionImagePath == null || auctionImagePath.isBlank()) {
			throw new IllegalStateException("auction.image.path 설정이 없습니다.");
		}

		Path imageDirectory = Path.of(auctionImagePath.trim()).toAbsolutePath().normalize();

		//폴더가 없으면 중간 경로까지 자동 생성
		Files.createDirectories(imageDirectory);

		if (!Files.isWritable(imageDirectory)) {
			throw new IllegalStateException("이미지 저장 폴더에 쓰기 권한이 없습니다: " + imageDirectory);
		}
		return imageDirectory.toFile();
	}
}
