//
//  MediaDetailViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit
import SnapKit
import Then

final class MediaDetailViewController: UIViewController {
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let contentView = UIView()
    
    private let backDropImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    
    private let shadowView = UIView().then {
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.8
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.backgroundColor = .clear
    }
    
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .leading
    }
    
    private let titleAndYearLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.numberOfLines = 0
    }
    
    private let mediaTypeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .gray
    }
    
    private let genreLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
    }
    
    private let actionButtonStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 8
    }

    private let watchlistButton = UIButton()
    
    private let reviewButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        
        config.image = UIImage(systemName: "sunglasses")?.withTintColor(.systemRed)
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        
        config.title = "평가하기"
        config.attributedTitle?.font = .systemFont(ofSize: 12, weight: .semibold)
        config.imagePlacement = .top
        config.imagePadding = 8
        
        
        config.baseForegroundColor = .darkGray
        
        $0.configuration = config
    }
    
    private let overviewLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.numberOfLines = 0
        $0.textColor = .darkGray
    }
    
    private let creditsLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
    }
    
    private let reactor: MediaDetailReactor
    private let disposeBag = DisposeBag()
    
    init(reactor: MediaDetailReactor) {
        self.reactor = reactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        configureHierarchy()
        configureLayout()
        bind()
        
        reactor.action.onNext(.viewDidLoad)
    }
    
    private func bind() {
        bindState(reactor: reactor)
        bindAction(reactor: reactor)
    }
    
    private func bindState(reactor: MediaDetailReactor) {
        
        reactor.state.compactMap { $0.mediaDetail }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, detail in
                let mediaInfo = detail.mediaInfo
                
                switch mediaInfo.mediaType {
                case .movie:
                    owner.mediaTypeLabel.text = "영화"
                case .tv:
                    owner.mediaTypeLabel.text = "TV 시리즈"
                default:
                    owner.mediaTypeLabel.text = ""
                }
                
                let yearString = mediaInfo.releaseDate.map { String($0.prefix(4)) }
                owner.titleAndYearLabel.attributedText = owner.setTitleStyle(title: mediaInfo.title, year: yearString)
                owner.overviewLabel.text = mediaInfo.overview
                
                owner.genreLabel.text = API.convertGenreString(mediaInfo.mediaType, array: mediaInfo.genreIDS).joined(separator: " / ")
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.backDropImageData }
            .bind(with: self) { owner, image in
                if let image = image {
                    owner.backDropImageView.image = image
                } else {
                    owner.backDropImageView.backgroundColor = .systemGray6
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.posterImageData }
            .bind(with: self) { owner, image in
                if let image = image {
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = .systemGray6
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.errorType }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, error in
                print("로드 에러: \(error.localizedDescription)")
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.isWatchlisted }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, isWatchlisted in
                owner.updateWatchlistButton(isWatchlisted: isWatchlisted)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(reactor: MediaDetailReactor) {
        watchlistButton.rx.tap
            .map { MediaDetailReactor.Action.watchlistButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap
            .bind(with: self) { owner, _ in
                
            }
            .disposed(by: disposeBag)
    }
    
    private func updateWatchlistButton(isWatchlisted: Bool) {
        var config = UIButton.Configuration.plain()

        config.preferredSymbolConfigurationForImage = .init(pointSize: 20)
        config.imagePlacement = .top
        config.imagePadding = 8

        let titleText: String
        let color: UIColor
        let imageName: String

        if isWatchlisted {
            titleText = "보고 싶은 미디어에 저장됨"
            color = .systemBlue
            imageName = "checkmark.circle.fill"
        } else {
            titleText = "보고 싶어요"
            color = .darkGray
            imageName = "plus.circle"
        }

        config.image = UIImage(systemName: imageName)
        config.baseForegroundColor = color

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let nsAttr = NSAttributedString(
            string: titleText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .paragraphStyle: paragraphStyle
            ]
        )

        if let attr = try? AttributedString(nsAttr, including: \.uiKit) {
            config.attributedTitle = attr
        }

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.watchlistButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.watchlistButton.alpha = 0.0
            }, completion: { _ in
                self.watchlistButton.configuration = config
                
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                    self.watchlistButton.transform = .identity
                    self.watchlistButton.alpha = 1.0
                })
            })
        }
    }
}

extension MediaDetailViewController {
    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(backDropImageView)
        contentView.addSubview(shadowView)
        shadowView.addSubview(posterImageView)
        
        contentView.addSubview(infoStackView)
        [titleAndYearLabel, mediaTypeLabel, genreLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(actionButtonStackView)
        [watchlistButton, reviewButton].forEach {
            actionButtonStackView.addArrangedSubview($0)
        }
        
        contentView.addSubview(overviewLabel)
        contentView.addSubview(creditsLabel)
    }
    
    private func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }
        
        backDropImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(contentView)
            $0.height.equalTo(200)
        }
        
        shadowView.snp.makeConstraints {
            $0.top.equalTo(backDropImageView.snp.bottom).inset(50)
            $0.leading.equalTo(contentView).offset(20)
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(180)
        }
        
        posterImageView.snp.makeConstraints {
            $0.edges.equalTo(shadowView)
        }
        
        infoStackView.snp.makeConstraints {
            $0.top.equalTo(backDropImageView.snp.bottom).offset(15)
            $0.leading.equalTo(shadowView.snp.trailing).offset(15)
            $0.trailing.equalTo(contentView).inset(20)
        }
        
        actionButtonStackView.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(15)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(actionButtonStackView.snp.bottom).offset(15)
            $0.horizontalEdges.equalTo(contentView).inset(20)
        }
        
        creditsLabel.snp.makeConstraints {
            $0.top.equalTo(overviewLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalTo(contentView).inset(20)
            $0.height.equalTo(800)
            $0.bottom.equalTo(contentView).inset(10)
        }
    }
}

extension MediaDetailViewController {
    func setTitleStyle(title: String, year: String?) -> NSAttributedString {
        let fullText: String
        if let year = year {
            fullText = "\(title) \(year)"
        } else {
            fullText = title
        }
        
        let attributed = NSMutableAttributedString(string: fullText)
        
        if let year = year,
           let range = fullText.range(of: "\(year)") {
            let nsRange = NSRange(range, in: fullText)
            
            attributed.addAttributes([
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ], range: nsRange)
        }
        
        return attributed
    }
}
