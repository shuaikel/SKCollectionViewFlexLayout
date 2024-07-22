#if os(iOS)
import UIKit

public let UICollectionElementKindSectionBackground = "UICollectionElementKindSectionBackground"
public let UICollectionElementKindItemBackground    = "UICollectionElementKindItemBackground"

open class UICollectionViewFlexLayout: UICollectionViewFlowLayout {
    
    private(set) var sectionHeaderAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private(set) var sectionFooterAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    private(set) var layoutAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private(set) var sectionBackgroundAttributes: [Int: UICollectionViewLayoutAttributes] = [:]
    private(set) var itemBackgroundAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private(set) var cachedContentSize: CGSize = .zero
    
    private(set) var minYSectionAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    private(set) var maxYSectionAttribute: [Int: UICollectionViewLayoutAttributes] = [:]
    
    private(set) var minimumItemZIndex: Int = 0
    
    override open func prepare() {
        self.prepareItemAttributes()
        self.prepareSectionAttributes()
        self.prepareZIndex()
    }
    // 布局
    private func prepareItemAttributes() {
        guard let collectionView = self.collectionView else { return }
        let contentWidth = collectionView.frame.width
        var offset: CGPoint = .zero
        
        self.layoutAttributes.removeAll()
        self.itemBackgroundAttributes.removeAll()
        self.minYSectionAttribute.removeAll()
        self.maxYSectionAttribute.removeAll()
        self.sectionHeaderAttributes.removeAll()
        self.sectionFooterAttributes.removeAll()
        
        for section in 0..<collectionView.numberOfSections {
            let sectionMargin = self.margin(forSectionAt: section)
            let sectionPadding = self.padding(forSectionAt: section)
            
            // maximum value of (height + padding bottom + margin bottom) in current row
            var maxItemBottom: CGFloat = 0
            
            offset.x = sectionMargin.left + sectionPadding.left // start from left
            offset.y = sectionMargin.top + sectionPadding.top // accumulated
            
            // header
            var sectionHeaderAttribute: UICollectionViewLayoutAttributes?
            if let headerAttribute = self.prepareSectionHeaderAttributes(section) {
                offset.y += headerAttribute.frame.maxY
                sectionHeaderAttribute = headerAttribute
            }
 
            let sectionItemCount = collectionView.numberOfItems(inSection: section)
            
            // item
            for item in 0..<sectionItemCount {
                let indexPath = IndexPath(item: item, section: section)
                let itemMargin = self.margin(forItemAt: indexPath)
                let itemPadding = self.padding(forItemAt: indexPath)
                let itemSize = self.size(forItemAt: indexPath)
                
                if item > 0 {
                    offset.x += self.horizontalSpacing(betweenItemAt: IndexPath(item: item - 1, section: section), and: indexPath)
                }
                if offset.x + itemMargin.left + itemPadding.left + itemSize.width + itemPadding.right + itemMargin.right + sectionPadding.right + sectionMargin.right > contentWidth {
                    offset.x = sectionMargin.left + sectionPadding.left // start from left
                    offset.y += maxItemBottom // next line
                    if item > 0 {
                        offset.y += self.verticalSpacing(betweenItemAt: IndexPath(item: item - 1, section: section), and: indexPath)
                    }
                    maxItemBottom = 0
                }
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.size = itemSize
                attributes.frame.origin.x = offset.x + itemMargin.left + itemPadding.left
                attributes.frame.origin.y = offset.y + itemMargin.top + itemPadding.top
                attributes.zIndex = self.zIndex(forItemAt: indexPath)
                
                let backgroundAttributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionElementKindItemBackground,
                    with: indexPath
                )
                backgroundAttributes.frame = CGRect(
                    x: attributes.frame.minX - itemPadding.left,
                    y: attributes.frame.minY - itemPadding.top,
                    width: attributes.frame.width + itemPadding.left + itemPadding.right,
                    height: attributes.frame.height + itemPadding.top + itemPadding.bottom
                )
                backgroundAttributes.zIndex = -1
                self.itemBackgroundAttributes[indexPath] = backgroundAttributes
                
                offset.x += itemMargin.left + itemPadding.left + itemSize.width + itemPadding.right + itemMargin.right
                maxItemBottom = max(maxItemBottom, itemMargin.top + itemPadding.top + itemSize.height + itemPadding.bottom + itemMargin.bottom)
                self.layoutAttributes[indexPath] = attributes
                
                if self.minYSectionAttribute[section]?.frame.minY ?? .greatestFiniteMagnitude > attributes.frame.minY {
                    self.minYSectionAttribute[section] = attributes
                }
                if self.maxYSectionAttribute[section]?.frame.maxY ?? -.greatestFiniteMagnitude < attributes.frame.maxY {
                    self.maxYSectionAttribute[section] = attributes
                }
                if self.minimumItemZIndex > attributes.zIndex {
                    self.minimumItemZIndex = attributes.zIndex
                }
            }
           
            // 如果当前sectionitemrow为空
            if sectionItemCount == 0 {
                
                if self.minYSectionAttribute[section]?.frame.minY ?? .greatestFiniteMagnitude > sectionHeaderAttribute?.frame.minY ?? .greatestFiniteMagnitude {
                    self.minYSectionAttribute[section] = sectionHeaderAttribute
                }
                if self.maxYSectionAttribute[section]?.frame.maxY ?? -.greatestFiniteMagnitude < sectionHeaderAttribute?.frame.maxY ?? .greatestFiniteMagnitude {
                    self.maxYSectionAttribute[section] = sectionHeaderAttribute
                }
            }
            
            offset.y += maxItemBottom + sectionPadding.bottom + sectionMargin.bottom
            
            // footer
            if  let sectionFooterAttribute = self.prepareSectionFooterAttributes(section) {
                if self.minYSectionAttribute[section]?.frame.minY ?? .greatestFiniteMagnitude > sectionFooterAttribute.frame.minY {
                    self.minYSectionAttribute[section] = sectionFooterAttribute
                }
                if self.maxYSectionAttribute[section]?.frame.maxY ?? -.greatestFiniteMagnitude < sectionFooterAttribute.frame.maxY {
                    self.maxYSectionAttribute[section] = sectionFooterAttribute
                }
                offset.y += sectionFooterAttribute.frame.height
            }
            

            self.cachedContentSize = CGSize(width: contentWidth, height: offset.y)
        }
    }
    
    private func prepareSectionHeaderAttributes(_ section: Int) -> UICollectionViewLayoutAttributes?{
        // header
        guard let collectionView = self.collectionView else { return nil}
        let sectionMargin = self.margin(forSectionAt: section)
        let sectionPadding = self.padding(forSectionAt: section)
        let sectionIndexPath = IndexPath(item: 0, section: section)
        let sectionHeaderSize = self.collectionView(collectionView, frameForHeader: true, inSection: section)
        let sectionHeaderAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,with: sectionIndexPath)
        var sectionLayoutY: CGFloat = 0
        if section > 0 {
            let preSectionAttribute:UICollectionViewLayoutAttributes = self.maxYSectionAttribute[section - 1]!
            sectionLayoutY = preSectionAttribute.frame.maxY + sectionMargin.top
        }
        
        var sectionVerticalSpacing: CGFloat = 0
        if section > 0 {
            sectionVerticalSpacing = self.verticalSpacing(betweenSectionAt: section - 1, and: section)
        }
        sectionLayoutY += sectionVerticalSpacing
        
        sectionHeaderAttribute.frame = CGRect(
            x: sectionPadding.left,
            y: sectionLayoutY,
            width: sectionHeaderSize.width,
            height: sectionHeaderSize.height
        )
        self.sectionHeaderAttributes[sectionIndexPath] = sectionHeaderAttribute
        return sectionHeaderAttribute
    }
    
    private func prepareSectionFooterAttributes(_ section: Int) -> UICollectionViewLayoutAttributes? {
        // footer
        guard let collectionView = self.collectionView else { return nil}
        let sectionIndexPath = IndexPath(item: 0, section: section)
        let sectionPadding = self.padding(forSectionAt: section)
        
        let sectionFooterSize = self.collectionView(collectionView, frameForHeader: false, inSection: section)
        let sectionFooterAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                                                      with: sectionIndexPath)
        let sectionFooterLayoutY: CGFloat = self.maxYSectionAttribute[section]?.frame.maxY  ?? 0
        sectionFooterAttribute.frame = CGRect(
            x: sectionPadding.left,
            y: sectionFooterLayoutY,
            width: sectionFooterSize.width,
            height: sectionFooterSize.height
        )
        self.sectionFooterAttributes[sectionIndexPath] = sectionFooterAttribute
        return sectionFooterAttribute
    }
    
    private func prepareSectionAttributes() {
        guard let collectionView = self.collectionView else { return }
        self.sectionBackgroundAttributes.removeAll()
        for section in 0..<collectionView.numberOfSections {
            guard let minYAttribute = self.minYSectionAttribute[section] else { continue }
            guard let maxYAttribute = self.maxYSectionAttribute[section] else { continue }
            let minY = minYAttribute.frame.minY
            let maxY = maxYAttribute.frame.maxY
            let sectionMargin = self.margin(forSectionAt: section)
            let width = collectionView.frame.width - sectionMargin.left - sectionMargin.right
            
            var height = maxY - minY
            // footer
            let sectionIndexPath = IndexPath(item: 0, section: section)
            if let sectionFooterAttribute = self.sectionFooterAttributes[sectionIndexPath] {
                height -= sectionFooterAttribute.frame.height
            }
            guard width > 0 && height > 0 else { continue }
            
            let sectionPadding = self.padding(forSectionAt: section)
            let attributes = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind: UICollectionElementKindSectionBackground,
                with: IndexPath(item: 0, section: section)
            )
            
            let itemMarginTop = self.margin(forItemAt: minYAttribute.indexPath).top
            let itemMarginBottom = self.margin(forItemAt: maxYAttribute.indexPath).bottom
            
            let itemPaddingTop = self.padding(forItemAt: minYAttribute.indexPath).top
            let itemPaddingBottom = self.padding(forItemAt: maxYAttribute.indexPath).bottom
            
            attributes.frame = CGRect(
                x: sectionMargin.left,
                y: minY - sectionPadding.top - itemPaddingTop - itemMarginTop,
                width: width,
                height: height + sectionPadding.top + sectionPadding.bottom + itemPaddingTop + itemPaddingBottom + itemMarginTop + itemMarginBottom
            )
            self.sectionBackgroundAttributes[section] = attributes
        }
    }
    
    private func prepareZIndex() {
        for attributes in self.itemBackgroundAttributes.values {
            attributes.zIndex = self.minimumItemZIndex - 1
        }
        for attributes in self.sectionBackgroundAttributes.values {
            attributes.zIndex = self.minimumItemZIndex - 2
        }
    }
    
    override open var collectionViewContentSize: CGSize {
        return self.cachedContentSize
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.layoutAttributes.values.filter { $0.frame.intersects(rect) }
        + self.sectionBackgroundAttributes.values.filter { $0.frame.intersects(rect) }
        + self.itemBackgroundAttributes.values.filter { $0.frame.intersects(rect) }
        + self.sectionHeaderAttributes.values.filter { $0.frame.intersects(rect) }
        + self.sectionFooterAttributes.values.filter { $0.frame.intersects(rect) }
    }
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.layoutAttributes[indexPath]
    }
    
    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionElementKindSectionBackground:
            guard indexPath.item == 0 else { return nil }
            return self.sectionBackgroundAttributes[indexPath.section]
            
        case UICollectionElementKindItemBackground:
            return self.itemBackgroundAttributes[indexPath]
            
        case UICollectionView.elementKindSectionHeader:
            return self.sectionHeaderAttributes[indexPath]
            
        case UICollectionView.elementKindSectionFooter:
            return self.sectionFooterAttributes[indexPath]
            
        default:
            return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        }
    }
    
    open func maximumWidth(forItemAt indexPath: IndexPath) -> CGFloat {
        guard let collectionView = self.collectionView else { return 0 }
        let sectionMargin = self.margin(forSectionAt: indexPath.section)
        let sectionPadding = self.padding(forSectionAt: indexPath.section)
        let itemMargin = self.margin(forItemAt: indexPath)
        let itemPadding = self.padding(forItemAt: indexPath)
        return collectionView.frame.width
        - sectionMargin.left
        - sectionPadding.left
        - itemMargin.left
        - itemPadding.left
        - itemPadding.right
        - itemMargin.right
        - sectionPadding.right
        - sectionMargin.right
    }
    
    // MARK: - UICollectionViewLayout Helpers
    private func collectionView(_ collectionView:UICollectionView, frameForHeader isForHeader:Bool, inSection section:Int) -> CGRect {
        let contentWidth = collectionView.frame.width
        let size = referenceSizeForHeader(isForHeader, inSection: section)
        let padding = self.padding(forSectionAt: section)
        let frame = CGRect(x: padding.left, y: self.cachedContentSize.height, width: size.width, height: size.height)
        self.cachedContentSize = CGSize(width: contentWidth, height: self.cachedContentSize.height+size.height)
        return frame
    }
}

extension UICollectionViewFlexLayout {
    var delegate: UICollectionViewDelegateFlexLayout? {
        return self.collectionView?.delegate as? UICollectionViewDelegateFlexLayout
    }
    
    public func size(forItemAt indexPath: IndexPath) -> CGSize {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) ?? .zero
    }
    
    public func verticalSpacing(betweenSectionAt section: Int, and nextSection: Int) -> CGFloat {
        guard section != nextSection else { return 0 }
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return 0 }
        return delegate.collectionView?(collectionView, layout: self, verticalSpacingBetweenSectionAt: section, and: nextSection) ?? 0
    }
    
    public func margin(forSectionAt section: Int) -> UIEdgeInsets {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return delegate.collectionView?(collectionView, layout: self, marginForSectionAt: section) ?? .zero
    }
    
    public func padding(forSectionAt section: Int) -> UIEdgeInsets {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return delegate.collectionView?(collectionView, layout: self, paddingForSectionAt: section) ?? .zero
    }
    
    public func horizontalSpacing(betweenItemAt indexPath: IndexPath, and nextIndexPath: IndexPath) -> CGFloat {
        guard indexPath != nextIndexPath else { return 0 }
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return 0 }
        return delegate.collectionView?(collectionView, layout: self, horizontalSpacingBetweenItemAt: indexPath, and: nextIndexPath) ?? 0
    }
    
    public func verticalSpacing(betweenItemAt indexPath: IndexPath, and nextIndexPath: IndexPath) -> CGFloat {
        guard indexPath != nextIndexPath else { return 0 }
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return 0 }
        return delegate.collectionView?(collectionView, layout: self, verticalSpacingBetweenItemAt: indexPath, and: nextIndexPath) ?? 0
    }
    
    public func margin(forItemAt indexPath: IndexPath) -> UIEdgeInsets {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return delegate.collectionView?(collectionView, layout: self, marginForItemAt: indexPath) ?? .zero
    }
    
    public func padding(forItemAt indexPath: IndexPath) -> UIEdgeInsets {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return delegate.collectionView?(collectionView, layout: self, paddingForItemAt: indexPath) ?? .zero
    }
    
    public func zIndex(forItemAt indexPath: IndexPath) -> Int {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        return .zero
    }
    
    public func referenceSizeForHeader(_ isForHeader: Bool, inSection section: Int) -> CGSize {
        guard let collectionView = self.collectionView, let delegate = self.delegate else { return .zero }
        if isForHeader {
            return delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) ?? .zero
        } else {
            return delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) ?? .zero
        }
    }
}
#endif
