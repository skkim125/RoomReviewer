//
//  VideoCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/25/25.
//

import UIKit
import ReactorKit
import SnapKit
import Then

final class VideoCollectionViewCell: UICollectionViewCell, View {
    static let cellID = "VideoCollectionViewCell"
    var disposeBag = DisposeBag()
    
    private let videoImageView = UIImageView().then {
        $0.alpha = 0.8
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = AppColor.appLightGray
        $0.tintColor = AppColor.appWhite
        $0.layer.borderWidth = 0.3
        $0.layer.borderColor = AppColor.appWhite.withAlphaComponent(0.3).cgColor
    }
    
    private let videoNameLabel = UILabel().then {
        $0.font = AppFont.semiboldSubTitle
        $0.textColor = AppColor.appWhite
        $0.textAlignment = .center
    }
    
    private let videoPlayButton = UIImageView().then {
        let paletteConfig = UIImage.SymbolConfiguration(paletteColors: [AppColor.appGray, AppColor.appWhite])
            .applying(UIImage.SymbolConfiguration(pointSize: 50))
        
        let image = UIImage(systemName: "play.circle.fill")?.withConfiguration(paletteConfig)
        $0.image = image
        $0.contentMode = .scaleAspectFit
    }
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        contentView.addSubview(videoImageView)
        contentView.addSubview(videoNameLabel)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(videoPlayButton)
    }
    
    private func configureLayout() {
        videoImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(contentView.safeAreaLayoutGuide)
            $0.bottom.equalTo(videoNameLabel.snp.top).offset(-5)
        }
        
        videoNameLabel.snp.makeConstraints {
            $0.height.equalTo(AppFont.semiboldSubTitle.lineHeight)
            $0.horizontalEdges.equalToSuperview().inset(5)
            $0.bottom.equalTo(contentView.safeAreaLayoutGuide).inset(1)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(videoImageView)
        }
        
        videoPlayButton.snp.makeConstraints {
            $0.center.equalTo(videoImageView)
            $0.size.equalTo(50)
        }
    }
    
    func bind(reactor: VideoCollectionViewCellReactor) {
        let isLoadingStream = reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .share()
        
        isLoadingStream
            .observe(on: MainScheduler.instance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        isLoadingStream
            .observe(on: MainScheduler.instance)
            .bind(to: videoPlayButton.rx.isHidden)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.videoThumnailImage }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: videoImageView.rx.image)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.videoName }
            .observe(on: MainScheduler.instance)
            .bind(to: videoNameLabel.rx.text)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.videoThumnailImage }
            .distinctUntilChanged()
            .filter { $0 == nil }
            .map { _ in VideoCollectionViewCellReactor.Action.loadImage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        videoImageView.image = nil
        videoNameLabel.text = nil
        reactor = nil
    }
}
