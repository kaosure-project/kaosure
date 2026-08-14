export interface ApiMeta {
  request_id: string;
  trace_id?: string;
}

export interface ApiSuccess<T> {
  success: true;
  data: T;
  meta: ApiMeta;
}

export interface ApiError {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta: ApiMeta;
}

export function successResponse<T>(
  data: T,
  requestId: string,
  traceId?: string,
): ApiSuccess<T> {
  const meta: ApiMeta = {
    request_id: requestId,
  };

  if (traceId !== undefined) {
    meta.trace_id = traceId;
  }

  return {
    success: true,
    data,
    meta,
  };
}

export function errorResponse(
  code: string,
  message: string,
  requestId: string,
  traceId?: string,
  details?: unknown,
): ApiError {
  const meta: ApiMeta = {
    request_id: requestId,
  };

  if (traceId !== undefined) {
    meta.trace_id = traceId;
  }

  return {
    success: false,
    error: {
      code,
      message,
      ...(details !== undefined ? { details } : {}),
    },
    meta,
  };
}