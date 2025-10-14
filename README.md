# 🍿 방구석 평론가 ReadMe

## 🍿 프로젝트 소개
> 내가 감상한 컨텐츠를 확인하고 평론을 하는 라이프스타일 앱


<img src="https://github.com/user-attachments/assets/1a0fe1bb-e91c-42a9-8bf4-123c3c1bc8ef" width="19.5%"/>
<img src="https://github.com/user-attachments/assets/3f8dd55c-0804-48a7-817c-5972ce6297c5" width="19.5%"/>
<img src="https://github.com/user-attachments/assets/a5c30266-88bb-48b7-b265-f408311ab88f" width="19.5%"/>
<img src="https://github.com/user-attachments/assets/3ad5d352-3925-4168-83cb-592dcf9ad422" width="19.5%"/>
<img src="https://github.com/user-attachments/assets/0c452459-73a1-4582-b4ee-69e858552b91" width="19.5%"/>

<br>

## 🍿 프로젝트 환경
- 인원: 1명
- 출시 개발 기간: 2025.08.11~2025.09.15
- 유지 보수 기간: 2025.09.18 ~ 진행중
- 개발 환경: Xcode 16
- 최소 버전: iOS 15.0+
<br>

## 🍿 기술 스택
- UIKit, CodeBaseUI
- RxSwift, ReactorKit, SnapKit, XCTest
- Compositional Layout, CoreData, URLScheme, URLSession
- TMDB API, Firebase Anaylitics, Firebase Crashlytics, Google AdMob
<br>

## 🍿 핵심 기능
- 매주 트렌드한 컨텐츠, 핫한 컨텐츠에 대한 확인 기능
- 컨텐츠에 대한 상세 정보 확인, 컨텐츠 저장 & 시청기록 & 즐겨찾기 기능
- 저장한 컨텐츠에 대해 티어 리스트 제작 기능
- 컨텐츠를 저장한 타입에 따라 확인 및 문의하기 기능
<br>

## 🍿 주요 기술
- RxSwift + ReactorKit
  - RxSwift와 ReactorKit을 활용하여 단방향 반응형 프로그래밍 구현
  - RxDataSource를 활용하여 Section과 데이터별로 CollectionView의 Cell UI를 구성하도록 구현
- CoreData
  - CoreData를 활용한 데이터베이스 구축 및 CRUD 메서드 구현
- Firebase & Google AdMob
  - Firebase의 Crashytics와 Anaylitics를 활용하여 사용자의 사용 패턴 확인 및 버그 정보 수집 구현
  - Google AdMob API를 활용하여 광고 노출 및 수익 창출성 고려
- URLSession을 사용한 NetworkManager 구현
  - Generic을 활용하여 Decodable한 타입들로 디코딩 진행
  - API Networking에 대한 요소들을 Router Pattern으로 추상화
- 이미지 처리 방식 개선
  - API를 통해 이미지 원본 데이터를 요청한 이후 Downsampling을 진행 후 표시하도록 하여 메모리 효율성 관리
  - Downsampling된 이미지를 캐싱에 추가하도록 하여 메모리 관리 효율성 개선
- 네트워크 및 이미지 캐싱 구현
  - URLCache를 활용하여 1차적으로 네트워크 응답에 대한 효율성 개선
  - 최종적으로 NSCache를 통해 이미지 캐싱을 진행하여 메모리 관리 효율성 개선
- ScrollViewDelegate를 활용한 Drag & Drop 기능 구현
  - ScrollView Drag & Drop Delegate를 활용하여 섹션간의 셀 이동 로직 구현
- FileManager를 활용하여 저장된 미디어에 대한 이미지들을 저장하도록 구현
<br>


