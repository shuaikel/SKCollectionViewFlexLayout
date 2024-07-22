#if os(iOS)
import UIKit

/// 代理回调
@objc public protocol UICollectionViewDelegateFlexLayout: UICollectionViewDelegate {
    
    /// section之间的间距
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, verticalSpacingBetweenSectionAt section: Int, and nextSection: Int) -> CGFloat
    
    /// section 和父容器之间的margin
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, marginForSectionAt section: Int) -> UIEdgeInsets
    
    /// section layout item padding
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, paddingForSectionAt section: Int) -> UIEdgeInsets
    
    /// cell水平间距
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, horizontalSpacingBetweenItemAt indexPath: IndexPath, and nextIndexPath: IndexPath) -> CGFloat
    
    /// cell 垂直方向间距
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, verticalSpacingBetweenItemAt indexPath: IndexPath, and nextIndexPath: IndexPath) -> CGFloat
    
    /// item cell相对于父容器的margin
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, marginForItemAt indexPath: IndexPath) -> UIEdgeInsets
    
    /// item cell布局padding
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, paddingForItemAt indexPath: IndexPath) -> UIEdgeInsets
    
    /// cell item layout size
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    
    /// section header layout size
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    
    /// section footer layout size
  @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlexLayout, referenceSizeForFooterInSection section: Int) -> CGSize
}
#endif
