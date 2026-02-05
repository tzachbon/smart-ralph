/**
 * Sample Model - Test Fixture
 * Used for manual testing of /ralph-specum:index command
 */

export type ModelStatus = 'active' | 'inactive' | 'pending' | 'archived';

export interface SampleModel {
  id: string;
  name: string;
  description: string;
  status: ModelStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface SampleModelCreateInput {
  name: string;
  description?: string;
  status?: ModelStatus;
}

export interface SampleModelUpdateInput {
  name?: string;
  description?: string;
  status?: ModelStatus;
}

export class SampleModelEntity implements SampleModel {
  id: string;
  name: string;
  description: string;
  status: ModelStatus;
  createdAt: Date;
  updatedAt: Date;

  constructor(data: SampleModel) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.status = data.status;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }

  /**
   * Check if model is active
   */
  isActive(): boolean {
    return this.status === 'active';
  }

  /**
   * Check if model can be modified
   */
  isEditable(): boolean {
    return this.status !== 'archived';
  }

  /**
   * Convert to plain object
   */
  toJSON(): SampleModel {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      status: this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }

  /**
   * Create from plain object
   */
  static fromJSON(data: SampleModel): SampleModelEntity {
    return new SampleModelEntity(data);
  }
}

export default SampleModel;
