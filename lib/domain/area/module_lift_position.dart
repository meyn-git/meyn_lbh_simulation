enum LiftPosition {
  // conveyor with a single module is in top position of destacker
  // to put the module on the supports or to get the module from the supports
  singleModuleAtSupports,
  // conveyor with two stacked modules is in the middule position of destacker
  // to put the top module on the supports or to get the top module from the supports
  topModuleAtSupport,
  inFeed,
  outFeed,
}
