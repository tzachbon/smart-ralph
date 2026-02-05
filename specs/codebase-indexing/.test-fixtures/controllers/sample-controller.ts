/**
 * Sample Controller - Test Fixture
 * Used for manual testing of /ralph-specum:index command
 */

import { Request, Response } from 'express';
import { SampleService } from '../services/sample-service';
import { SampleModel } from '../models/sample-model';

export class SampleController {
  private sampleService: SampleService;

  constructor() {
    this.sampleService = new SampleService();
  }

  /**
   * Get all items
   */
  async getAll(req: Request, res: Response): Promise<void> {
    const items = await this.sampleService.findAll();
    res.json(items);
  }

  /**
   * Get item by ID
   */
  async getById(req: Request, res: Response): Promise<void> {
    const { id } = req.params;
    const item = await this.sampleService.findById(id);
    if (!item) {
      res.status(404).json({ error: 'Not found' });
      return;
    }
    res.json(item);
  }

  /**
   * Create new item
   */
  async create(req: Request, res: Response): Promise<void> {
    const data = req.body as Partial<SampleModel>;
    const item = await this.sampleService.create(data);
    res.status(201).json(item);
  }

  /**
   * Update item
   */
  async update(req: Request, res: Response): Promise<void> {
    const { id } = req.params;
    const data = req.body as Partial<SampleModel>;
    const item = await this.sampleService.update(id, data);
    res.json(item);
  }

  /**
   * Delete item
   */
  async delete(req: Request, res: Response): Promise<void> {
    const { id } = req.params;
    await this.sampleService.delete(id);
    res.status(204).send();
  }
}

export default SampleController;
