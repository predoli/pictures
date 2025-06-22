// Generated from OpenAPI specification
export interface Image {
  filename: string;
  file_path: string; // Absolute file path on server
  url: string; // Relative URL for HTTP access
  mime_type: string;
  size: number;
  width?: number;
  height?: number;
  modified_date: string; // ISO date-time string
}

export interface ImagesResponse {
  images: Image[];
  total_count: number;
}

export interface ErrorResponse {
  error: string;
  code: number;
}

export type OrderingMode = 'name_asc' | 'name_desc' | 'date_asc' | 'date_desc' | 'random';

export interface ImageQuery {
  count: number;
  ordering: OrderingMode;
  last_image?: string;
}