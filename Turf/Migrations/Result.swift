public enum Result<TSuccess> {
    case Success(TSuccess)
    case Failure(ErrorType)
}
