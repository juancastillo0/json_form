class Either<L extends Object, R extends Object> {
  Either.left(L this.left) : right = null;
  Either.right(R this.right) : left = null;

  final L? left;
  final R? right;

  bool get isLeft => left != null;
  bool get isRight => right != null;
}
