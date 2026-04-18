const importOverleafModules = () => [];

if (process.env.NODE_ENV === 'development') {
  importOverleafModules('devToolbar')
}
