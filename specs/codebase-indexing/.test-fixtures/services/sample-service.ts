/**
 * Sample Service - Test Fixture
 * Used for manual testing of /ralph-specum:index command
 */

import { SampleModel } from '../models/sample-model';
import { SampleRepository } from '../repositories/sample-repository';
import { Logger } from '../utils/logger';

export interface ServiceConfig {
  timeout: number;
  retries: number;
}

export class SampleService {
  private repository: SampleRepository;
  private logger: Logger;
  private config: ServiceConfig;

  constructor(config?: Partial<ServiceConfig>) {
    this.repository = new SampleRepository();
    this.logger = new Logger('SampleService');
    this.config = {
      timeout: config?.timeout ?? 5000,
      retries: config?.retries ?? 3
    };
  }

  /**
   * Find all items
   */
  async findAll(): Promise<SampleModel[]> {
    this.logger.info('Finding all items');
    return this.repository.findAll();
  }

  /**
   * Find item by ID
   */
  async findById(id: string): Promise<SampleModel | null> {
    this.logger.info(`Finding item by id: ${id}`);
    return this.repository.findById(id);
  }

  /**
   * Find items by criteria
   */
  async findByCriteria(criteria: Partial<SampleModel>): Promise<SampleModel[]> {
    this.logger.info('Finding items by criteria', criteria);
    return this.repository.findByCriteria(criteria);
  }

  /**
   * Create new item
   */
  async create(data: Partial<SampleModel>): Promise<SampleModel> {
    this.logger.info('Creating item', data);
    const validated = this.validate(data);
    return this.repository.create(validated);
  }

  /**
   * Update existing item
   */
  async update(id: string, data: Partial<SampleModel>): Promise<SampleModel> {
    this.logger.info(`Updating item ${id}`, data);
    const existing = await this.findById(id);
    if (!existing) {
      throw new Error(`Item not found: ${id}`);
    }
    const validated = this.validate({ ...existing, ...data });
    return this.repository.update(id, validated);
  }

  /**
   * Delete item
   */
  async delete(id: string): Promise<void> {
    this.logger.info(`Deleting item ${id}`);
    await this.repository.delete(id);
  }

  /**
   * Validate item data
   */
  private validate(data: Partial<SampleModel>): SampleModel {
    if (!data.name) {
      throw new Error('Name is required');
    }
    return {
      id: data.id ?? crypto.randomUUID(),
      name: data.name,
      description: data.description ?? '',
      status: data.status ?? 'active',
      createdAt: data.createdAt ?? new Date(),
      updatedAt: new Date()
    };
  }
}

export default SampleService;
