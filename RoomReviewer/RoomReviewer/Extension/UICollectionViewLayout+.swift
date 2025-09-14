//
//  UICollectionViewLayout+.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/28/25.
//

import UIKit

extension UICollectionViewLayout {
    static var homeCollectionViewLayout: UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            switch sectionIndex {
            case 0:
                return createHorizontalSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .estimated(480),
                    groupWidth: .fractionalWidth(0.75),
                    groupHeight: .estimated(480),
                    header: createSectionHeader(),
                    scrollingBehavior: .groupPaging
                )
            default:
                return createHorizontalSection(
                    itemWidth: .fractionalWidth(1.0),
                    itemHeight: .fractionalHeight(1.0),
                    groupWidth: .fractionalWidth(0.35),
                    groupHeight: .fractionalWidth(0.35 * 1.5),
                    header: createSectionHeader(),
                    scrollingBehavior: .continuous
                )
            }
        }
    }
    
    static var hotMediaCollectionViewLayout: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.3),
            heightDimension: .estimated(180)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 15
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    static var threeColumnPosterCollectionViewLayout: UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1/3),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let groupHeight = NSCollectionLayoutDimension.fractionalWidth(1/3 * 1.5)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: groupHeight
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
    
    static var creditsCollectionViewLayout: UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(120),
                heightDimension: .absolute(160)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(10)
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 15
            section.contentInsets = .init(top: 5, leading: 15, bottom: 10, trailing: 15)
            
            section.boundarySupplementaryItems = [createSectionHeader(height: .absolute(40))]
            
            return section
        }
    }
    
    static var trendMediaCollectionViewLayout: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .estimated(480))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        section.interGroupSpacing = 20
        section.orthogonalScrollingBehavior = .groupPaging
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        
        return section
    }
    
    static var myPageCollectionViewLayout: UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.backgroundColor = .clear
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        
        return layout
    }
    
    static var mediaTierListLayout: UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            // Tier List는 보통 고정된 크기의 아이템을 가로로 스크롤합니다.
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(100), // 고정 너비
                heightDimension: .absolute(150) // 고정 높이 (비율 1.5)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(100),
                heightDimension: .absolute(150)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous // 부드러운 가로 스크롤
            section.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            // Tier Section Header 추가
            section.boundarySupplementaryItems = [createSectionHeader(height: .absolute(44))]
            
            return section
        }
    }
}

extension UICollectionViewLayout {
    private static func createHorizontalSection(itemWidth: NSCollectionLayoutDimension,
                                                itemHeight: NSCollectionLayoutDimension,
                                                groupWidth: NSCollectionLayoutDimension,
                                                groupHeight: NSCollectionLayoutDimension,
                                                header: NSCollectionLayoutBoundarySupplementaryItem,
                                                scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior) -> NSCollectionLayoutSection { // <-- 파라미터 추가
        let itemSize = NSCollectionLayoutSize(widthDimension: itemWidth, heightDimension: itemHeight)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: groupWidth, heightDimension: groupHeight)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = scrollingBehavior // <-- 전달받은 값으로 설정
        section.interGroupSpacing = 15
        section.contentInsets = .init(top: 5, leading: 15, bottom: 15, trailing: 15)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    
    private static func createSectionHeader(height: NSCollectionLayoutDimension = .estimated(40)) -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: height
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}
