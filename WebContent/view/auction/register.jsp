<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>경매 상품 등록 화면</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/header.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/common/footer.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/auction/register.css">
</head>

<body class="auction-register-page">

<!-- 공통 HEADER -->

<jsp:include page="/view/common/header.jsp" />

<main class="main">

	<section class="auction-register">

		<div class="auction-register-inner">

			<div class="title-box">

				<h1 class="title">경매 상품 등록</h1>
			</div>

			<div class="guide-box">

				<p class="guide-text">· 경매는 등록 즉시 시작되며, 선택한 진행시간이 지나면 자동으로 종료됩니다.</p>
				<p class="guide-text">· 대표 이미지 1장과 추가 이미지를 함께 등록할 수 있습니다.</p>
			</div>

			<form
				action="${pageContext.request.contextPath}/api/auctionFlow/auction/register"
				method="post" enctype="multipart/form-data" class="form" id="auctionRegisterForm">

				<div class="form-row">

					<label for="auctionCategory" class="label">카테고리</label>

					<select id="auctionCategory" name="A_CATEGORY" class="input select-input" required>
						<option value="고서적" ${A_CATEGORY == '고서적' ? 'selected' : ''}>고서적</option>
						<option value="미술품" ${A_CATEGORY == '미술품' ? 'selected' : ''}>미술품</option>
						<option value="골동품" ${A_CATEGORY == '골동품' ? 'selected' : ''}>골동품</option>
						<option value="기타" ${A_CATEGORY == '기타' ? 'selected' : ''}>기타</option>
					</select>
				</div>

				<div class="form-row">

					<label for="auctionTitle" class="label">상품명</label>

					<input
						type="text" id="auctionTitle" name="A_TITLE" class="input" value="${A_TITLE}"
						placeholder="상품명을 입력해 주세요." maxlength="200" required>
				</div>

				<div class="form-row">

					<label for="auctionContent" class="label">상품 설명</label>

					<textarea id="auctionContent" name="A_CONTENT" class="textarea" placeholder="상품 설명을 입력해 주세요." required>${A_CONTENT}</textarea>
				</div>
				
				<div class="form-row">

					<label for="auctionDurationTime" class="label">경매 진행시간</label>
				
					<select id="auctionDurationTime" name="A_DURATION_TIME" class="input select-input" required>
					
						<option value="1" ${A_DURATION_TIME == '1' ? 'selected' : ''}>1분</option>
						<option value="5" ${A_DURATION_TIME == '5' ? 'selected' : ''}>5분</option>
						<option value="10" ${A_DURATION_TIME == '10' ? 'selected' : ''}>10분</option>
						<option value="30" ${A_DURATION_TIME == '30' ? 'selected' : ''}>30분</option>
						<option value="60" ${A_DURATION_TIME == '60' ? 'selected' : ''}>1시간</option>
						<option value="180" ${A_DURATION_TIME == '180' ? 'selected' : ''}>3시간</option>
						<option value="360" ${A_DURATION_TIME == '360' ? 'selected' : ''}>6시간</option>
						<option value="720" ${A_DURATION_TIME == '720' ? 'selected' : ''}>12시간</option>
						<option value="1440" ${A_DURATION_TIME == '1440' ? 'selected' : ''}>1일</option>
						<option value="4320" ${A_DURATION_TIME == '4320' ? 'selected' : ''}>3일</option>
						<option value="10080" ${A_DURATION_TIME == '10080' ? 'selected' : ''}>7일</option>
						<option value="20160" ${A_DURATION_TIME == '20160' ? 'selected' : ''}>14일</option>
						<option value="43200" ${A_DURATION_TIME == '43200' ? 'selected' : ''}>30일</option>
					</select>
					<p class="price-guide">등록 완료 시점부터 선택한 시간 동안 경매가 진행됩니다.</p>
				</div>
				
				<div class="form-row">
				
					<label for="mainImage" class="label">대표 이미지</label>
					
					<div class="file-box">
						
						<input type="file" id="mainImage" name="MAIN_IMAGE" class="file-input" required>
						
						<p class="file-guide">대표 이미지는 상품 목록과 상세 화면에서 가장 먼저 보이는 이미지입니다.</p>
						<p class="file-guide">허용 양식: jpg,jpeg,png,webp</p>
					</div>
				</div>
				
				<div class="form-row">
				
					<label class="label">추가 이미지</label>
					
					<div class="file-box">
					
						<div id="subImageList" class="sub-image-list">
						
							<div class="sub-image-row">
						
								<input type="file" name="SUB_IMAGES" class="file-input sub-image-input">
							</div>
						</div>
						
						<p class="file-guide">파일을 선택하면 다음 이미지 입력란이 자동으로 추가됩니다.</p>
						<p class="file-guide">선택하지 않아도 상품 등록은 가능합니다.</p>
						<p class="file-guide">허용 양식: jpg,jpeg,png,webp</p>
					</div>
				</div>

				<div class="form-row">

					<label for="auctionStartPrice" class="label">시작가</label>
					
					<div class="price-input-wrap">
						
						<button type="button" class="price-step-btn" id="priceMinusBtn">-</button>
						
						<input
						type="text" id="auctionStartPrice" name="A_START_PRICE" class="input price-input"
						value="${A_START_PRICE}" placeholder="시작가를 입력해 주세요." inputmode="numeric" required>
						
						<button type="button" class="price-step-btn" id="pricePlusBtn">+</button>
					</div>

					<p class="price-guide">시작가는 50,000원 단위로 조정할 수 있습니다.</p>
				</div>

				<p class="message auction-register-message">${AUCTION_REGISTER_MESSAGE}</p>

				<div class="button-area">

					<button type="submit" class="btn btn-submit">상품 등록</button>

					<a href="${pageContext.request.contextPath}/api/auctionFlow/main" class="btn btn-cancel">취소</a>
				</div>
			</form>
		</div>
	</section>
</main>

<!-- 공통 FOOTER -->
<jsp:include page="/view/common/footer.jsp" />

<script type="text/javascript">

document.addEventListener("DOMContentLoaded", function () {

	// =========================================================
	// 1. 시작가 입력 처리
	// =========================================================

	const auctionRegisterForm = document.getElementById("auctionRegisterForm");
	const priceInput = document.getElementById("auctionStartPrice");
	const priceMinusBtn = document.getElementById("priceMinusBtn");
	const pricePlusBtn = document.getElementById("pricePlusBtn");
	const PRICE_STEP = 50000;

	function removeComma(value) {

		if (!value) {
			return "";
		}

		return value.replaceAll(",", "").replace(/[^0-9]/g, "");
	}

	function addComma(value) {

		if (!value) {
			return "";
		}

		return Number(value).toLocaleString("ko-KR");
	}

	function getPriceNumber() {

		const numericText = removeComma(priceInput.value);

		if (!numericText) {
			return 0;
		}

		return Number(numericText);
	}

	function setPriceNumber(price) {

		if (price <= 0) {
			priceInput.value = "";
			return;
		}

		priceInput.value = addComma(String(price));
	}

	if (priceInput) {
		priceInput.addEventListener("input", function () {
			const numericText = removeComma(priceInput.value);
			priceInput.value = addComma(numericText);
		});

		if (priceInput.value) {
			priceInput.value = addComma(removeComma(priceInput.value));
		}
	}

	if (priceMinusBtn) {
		priceMinusBtn.addEventListener("click", function () {
			const currentPrice = getPriceNumber();
			const nextPrice = currentPrice - PRICE_STEP;
			
			if (nextPrice < PRICE_STEP) {
				setPriceNumber(PRICE_STEP);
				return;
			}
			setPriceNumber(nextPrice);
		});
	}

	if (pricePlusBtn) {
		pricePlusBtn.addEventListener("click", function () {
			const currentPrice = getPriceNumber();

			if (currentPrice === 0) {
				setPriceNumber(PRICE_STEP);
				return;
			}

			setPriceNumber(currentPrice + PRICE_STEP);
		});
	}

	if (auctionRegisterForm) {
		auctionRegisterForm.addEventListener("submit", function () {
	
			if (priceInput) {
				priceInput.value = removeComma(priceInput.value);
			}
	
			const subImageInputs = document.querySelectorAll("input[name='SUB_IMAGES']");
	
			subImageInputs.forEach(function (subImageInput) {
	
				if (!subImageInput.value) {
					subImageInput.disabled = true;
				}
			});
		});
	}

	// =========================================================
	// 2. 추가 이미지 input 자동 생성
	// =========================================================

	const subImageList = document.getElementById("subImageList");


	//새로운 빈 추가 이미지 입력 행을 생성한다.
	function createSubImageRow() {

		const subImageRow = document.createElement("div");

		subImageRow.className = "sub-image-row";

		const subImageInput = document.createElement("input");

		subImageInput.type = "file";

		subImageInput.name = "SUB_IMAGES";

		subImageInput.className = "file-input sub-image-input";

		subImageInput.accept = ".jpg,.jpeg,.png,.webp";

		subImageRow.appendChild(subImageInput);

		return subImageRow;
	}

	//파일이 선택된 행에 삭제 버튼을 추가한다.
	function addRemoveButton(subImageRow) {

		const existingRemoveButton = subImageRow.querySelector(".sub-image-remove-btn");

		if (existingRemoveButton) {
			return;
		}

		const removeButton = document.createElement("button");

		removeButton.type = "button";

		removeButton.className = "sub-image-remove-btn";

		removeButton.textContent = "삭제";

		subImageRow.appendChild(removeButton);
	}

	//목록 마지막에 빈 파일 입력란이 항상 하나 존재하도록 한다.
	function ensureEmptySubImageInput() {

		const subImageInputs = subImageList.querySelectorAll(".sub-image-input");

		if (subImageInputs.length === 0) {
			subImageList.appendChild(createSubImageRow());
			return;
		}

		const lastSubImageInput = subImageInputs[subImageInputs.length - 1];

		if (lastSubImageInput.files && lastSubImageInput.files.length > 0) {
			subImageList.appendChild(createSubImageRow());
		}
	}

	if (subImageList) {

		//동적으로 생성된 input에도 적용되도록 상위 목록에서 change 이벤트를 처리한다.
		subImageList.addEventListener("change", function (event) {

				const subImageInput = event.target;

				if (!subImageInput.classList.contains("sub-image-input")) {
					return;
				}

				const subImageRow = subImageInput.closest(".sub-image-row");

				//파일을 선택한 경우 현재 행에 삭제 버튼을 붙이고 아래에 빈 입력란을 생성한다.
				if (subImageInput.files && subImageInput.files.length > 0) {
					addRemoveButton(subImageRow);
					ensureEmptySubImageInput();
					return;
				}

				//이미 선택했던 파일을 취소한 경우, 마지막 빈 행이 아니면 해당 행을 삭제한다.
				const subImageRows = subImageList.querySelectorAll(".sub-image-row");
				const lastSubImageRow = subImageRows[subImageRows.length - 1];

				if (subImageRow !== lastSubImageRow) {
					subImageRow.remove();
				}

				ensureEmptySubImageInput();
			}
		);

		//동적으로 생성된 삭제 버튼 처리
		subImageList.addEventListener("click", function (event) {

				const removeButton = event.target.closest(".sub-image-remove-btn");

				if (!removeButton) {
					return;
				}

				const subImageRow = removeButton.closest(".sub-image-row");

				if (subImageRow) {
					subImageRow.remove();
				}

				ensureEmptySubImageInput();
			}
		);
	}
});
</script>
</body>
</html>