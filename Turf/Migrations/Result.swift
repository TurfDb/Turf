public enum Result<TSuccess> {
    case success(TSuccess)
    case failure(Error)
}
