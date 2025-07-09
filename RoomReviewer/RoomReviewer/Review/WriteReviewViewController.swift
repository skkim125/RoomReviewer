//
//  WriteReviewViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 7/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class WriteReviewViewController: UIViewController {
    private let searchTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.font = .systemFont(ofSize: 14)
        $0.returnKeyType = .search
        $0.placeholder = "검색어를 입력하세요"
    }
    
    private let writeReviewReactor: WriteReviewReactor
    private var disposeBag = DisposeBag()
    
    init(writeReviewReactor: WriteReviewReactor) {
        self.writeReviewReactor = writeReviewReactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
        bind()
        view.backgroundColor = .white
    }
    
    private func bind() {
        bindAction(reactor: writeReviewReactor)
        bindState(reactor: writeReviewReactor)
    }
    
    private func bindAction(reactor: WriteReviewReactor) {
        searchTextField.rx.text
            .distinctUntilChanged()
            .map { WriteReviewReactor.Action.updateQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchTextField.rx.controlEvent(.editingDidEndOnExit)
            .map { WriteReviewReactor.Action.searchButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.navigationItem.leftBarButtonItem?.rx.tap
            .map { WriteReviewReactor.Action.dismissWriteReview }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: WriteReviewReactor) {
        
        reactor.pulse(\.$medias)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                print("검색 결과: \(value.count)개")
                if value.isEmpty {
                    print("검색 결과가 없습니다")
                } else {
                    print(value.first?.originalName ?? "")
                }
            }
            .disposed(by: disposeBag)

        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                owner.searchTextField.isEnabled = !value
                if value {
                    print("검색 중...")
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.compactMap { $0.errorType }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                print("검색 에러")
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$dismissAction)
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.navigationController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension WriteReviewViewController {
    private func configureHierarchy() {
        view.addSubview(searchTextField)
    }
    
    private func configureLayout() {
        searchTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(40)
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "시청한 미디어 검색"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil)
    }
}
