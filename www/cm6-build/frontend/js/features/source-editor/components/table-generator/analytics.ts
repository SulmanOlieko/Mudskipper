// Stub out analytics to prevent crashes in visual editor
export const TableGeneratorAnalytics = {
  emitEvent: (event: string, metadata: any) => {
    // console.log('[Analytics Stub] Event:', event, metadata);
  }
};

export const emitTableGeneratorEvent = (event: string, metadata: any) => {
  // console.log('[Analytics Stub] Event:', event, metadata);
};
