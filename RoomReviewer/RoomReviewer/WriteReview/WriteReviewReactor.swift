//
//  WriteReviewReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/25/25.
//

import UIKit
import ReactorKit
import RxSwift

final class WriteReviewReactor: Reactor {
    
    struct State {
        let media: Media
        var contentType: MediaType
        var posterImage: UIImage?
        var rating: Double = 0
        var isSaving: Bool = false
        var canSave: Bool = false
        @Pulse var shouldDismiss: Void?
    }
    
    enum Action {
        case viewDidLoad
        case artistryScoreChanged(Double)
        
//        case saveButtonTapped
    }
    
    enum Mutation {
        case setPosterImage(UIImage?)
        case setRating(Double)
        case setSaving(Bool)
        case dismissView
    }
    
    var initialState: State
    
    private let dbManager: DBManager
    private let imageProvider: ImageProviding
    
    init(media: Media, dbManager: DBManager, imageProvider: ImageProviding) {
        self.initialState = State(media: media, contentType: media.mediaType)
        self.dbManager = dbManager
        self.imageProvider = imageProvider
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return loadPosterImage(currentState.media.posterPath)
            
        case .artistryScoreChanged(let score):
            return .just(.setRating(score))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setRating(let score):
            newState.rating = score
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .dismissView:
            newState.shouldDismiss = ()
        case .setPosterImage(let image):
            newState.posterImage = image
        }
        
        return newState
    }
    
    private func loadPosterImage(_ imagePath: String?) -> Observable<Mutation> {
        return imageProvider.fetchImage(from: imagePath)
            .map { image in
                return .setPosterImage(image)
            }
    }
}

