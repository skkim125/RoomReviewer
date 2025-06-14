//
//  HomeViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 6/13/25.
//

import UIKit
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {
    private var disposeBag = DisposeBag()
    private let homeReactor: HomeReactor
    
    init(reactor: HomeReactor) {
        self.homeReactor = reactor
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
        
        view.backgroundColor = .white
    }
    
    private func configureView() {
        configureHierarchy()
        configureLayout()
        configureUI()
    }
    
    private func bind() {
        bindAction(reactor: homeReactor)
        bindState(reactor: homeReactor)
    }
    
    private func bindAction(reactor: HomeReactor) {
        rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
            .map { HomeReactor.Action.fetchData }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: HomeReactor) {
        reactor.state.map({ $0.isLoading })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                
            }
            .disposed(by: disposeBag)
            
        reactor.state.map({ $0.tvs })
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                
            }
            .disposed(by: disposeBag)
    }
}

extension HomeViewController {
    private func configureHierarchy() {
        
    }
    
    private func configureLayout() {
        
    }
    
    private func configureUI() {
        
    }
}
