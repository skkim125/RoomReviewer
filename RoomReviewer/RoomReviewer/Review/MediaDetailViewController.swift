//
//  MediaDetailViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/13/25.
//

import UIKit
import RxSwift
import RxCocoa
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
                
                // owner.genreLabel.text = mediaInfo.genres.map { $0.name }.joined(separator: " / ")
                
                owner.genreLabel.text = "애니메이션 / 가족 / 판타지"
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
        
        infoStackView.addArrangedSubview(titleAndYearLabel)
        infoStackView.addArrangedSubview(mediaTypeLabel)
        infoStackView.addArrangedSubview(genreLabel)
        
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
        
        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(shadowView.snp.bottom).offset(20)
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
